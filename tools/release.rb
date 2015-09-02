# encoding:utf-8

# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

require "erb"

require_relative "release_checks"
require_relative "spec_template"

class Release
  def self.version
    if File.exist?("VERSION")
      File.read("VERSION").chomp
    else
      Machinery::VERSION
    end
  end

  def initialize(opts = {})
    @current_version = Release.version
    @options = {
      version:      Release.generate_development_version,
      skip_rpm_cleanup: false,
      jenkins_name:     "machinery-unit",
      changes_file:     "NEWS",
      rpm_changes_file: "RPM_CHANGES",
      package_name:     "machinery"
    }.merge(opts)
    @tag             = "v#{@options[:version]}"
    @release_time    = Time.now.strftime('%a %b %d %H:%M:%S %Z %Y')
    @mail            = Cheetah.run(["git", "config", "user.email"], :stdout => :capture).chomp
    @gemspec         = Gem::Specification.load("machinery.gemspec")
    @release_checks  = ReleaseChecks.new(@tag, @options[:jenkins_name])
    @changelog_files = [@options[:changes_file], @options[:rpm_changes_file]]
    @package_changes_path = "package/#{@options[:package_name]}.changes"
    set_version
    add_default_rpm_changes_entry
  end

  def check
    @release_checks.check
  end

  def prepare
    clean_up_tmp
    remove_old_releases(skip_rpm_cleanup: @options[:skip_rpm_cleanup])
    build_gem
    generate_specfile
    copy_rpmlintrc
    generate_changelog
  end

  def build_gem
    if File.exist?("machinery.gemspec")
      Cheetah.run "gem", "build", "machinery.gemspec"
      FileUtils.mv Dir.glob("machinery-*.gem"), "package/"
    end
  end

  # Update the version file, generate a changelog and RPM specfile and build
  # an RPM using osc
  def build_local
    prepare

    Rake::Task["osc:build"].invoke("--clean")

    # Collect built RPMs in package/, e.g. so that jenkins can collect them
    output_dir = File.join("/var/tmp", obs_project, build_dist)
    FileUtils.cp Dir.glob("#{output_dir}/*.rpm"), "package/"
  ensure
    # revert the version and changelog changes

    if File.exist?("lib/version.rb")
      Cheetah.run "git", "checkout", "lib/version.rb"
    else
      Cheetah.run "git", "checkout", "VERSION"
    end
    @changelog_files.each do |file|
      Cheetah.run "git", "checkout", file
    end
  end

  # Commit version changes, tag release and push changes upstream.
  def publish
    finalize_news_file
    prepare

    commit
  end

  # Calculates the next version number according to the release type (:major, :minor or :patch)
  def self.generate_release_version(release_type)
    major, minor, patch = version.scan(/(\d+)\.(\d+)\.(\d+)/).first.map(&:to_i)

    case release_type
    when "patch"
      patch += 1
    when "minor"
      patch = 0
      minor += 1
    when "major"
      patch = 0
      minor = 0
      major += 1
    end

    "#{major}.#{minor}.#{patch}"
  end

  def self.generate_development_version
    # The development version RPMs have the following version number scheme:
    # <base version>.<timestamp><os>git<short git hash>
    timestamp = Time.now.strftime("%Y%m%dT%H%M%SZ")
    commit_id = Cheetah.run("git", "rev-parse", "--short", "HEAD", stdout: :capture).chomp

    "#{Release.version}.#{timestamp}#{build_dist.gsub(/[._]/, "")}git#{commit_id}"
  end

  private

  def remove_old_releases(skip_rpm_cleanup: false)
    if skip_rpm_cleanup
      FileUtils.rm Dir.glob("package/*.gem")
    else
      FileUtils.rm Dir.glob("package/*")
    end
  end

  def clean_up_tmp
    output_dir = File.join("/var/tmp", obs_project, build_dist)
    FileUtils.rm Dir.glob("#{output_dir}/*.rpm")
  end

  def set_version
    if File.exist?("lib/version.rb")
      Cheetah.run "sed", "-i", "s/VERSION.*=.*/VERSION = \"#{@options[:version]}\"/",
        "lib/version.rb"
    else
      File.write("VERSION", @options[:version])
    end
  end

  def generate_specfile
    erb = ERB.new(File.read(Dir.glob("*.spec.erb").first), nil, "-")
    if File.exist?("#{@options[:package_name]}.gemspec")
      env = SpecTemplate.new(@options[:version], @gemspec)
    else
      arch = @options[:package_name][/^machinery-helper-(\w*)$/, 1]
      env = OpenStruct.new(version: @options[:version], arch: arch)
    end

    File.open("package/#{@options[:package_name]}.spec", "w+") do |spec_file|
      spec_file.puts erb.result(env.instance_eval { binding })
    end
  end

  def copy_rpmlintrc
    rpmlint = Dir.glob("*-rpmlintrc").first
    if rpmlint
      FileUtils.cp rpmlint, "package/#{@options[:package_name]}-rpmlintrc"
    end
  end

  def generate_changelog
    changes = { @options[:version] => create_rpm_header(@options[:version], @release_time, @mail) }
    news    = { @options[:version] => "" }
    @changelog_files.each do |file|
      version = @options[:version]
      time    = @release_time
      mail    = @mail

      File.open(file).each_line do |line|
        if line =~ /^## Version (\d+\.\d+.\d+) - (.+) - (.+)$/
          version = $1
          time    = $2
          mail    = $3
          changes[version] ||= "\n" + create_rpm_header(version, time, mail)
          news[version]    ||= ""
        elsif line =~ /^\* / || line =~ /^  \w/
          if file.include?("RPM_CHANGES")
            changes[version] += line.gsub(/^\* /, "- ")
          else
            if line =~ /^  \w/
              news[version] += line.gsub(/^\  /, "    ")
            else
              news[version] += line.gsub(/^\* /, "  * ")
            end
          end
        end
      end
    end

    news.each do |version, value|
      changes[version].gsub!(/- update to version #{version}\n/, "- update to version #{version}\n" + value)
    end

    changes = changes.sort_by do |version, value|
      version.split(".").map{ |s| s.to_i }
    end.reverse

    changelog = ""
    changes.each do |version, value|
      changelog += value
    end

    File.write(@package_changes_path, changelog)
  end

  def finalize_news_file
    @changelog_files.each do |file|
      content = File.read(file)
      # All changes for the next release are directly added below the headline
      # by the developers without adding a version line.
      # Since the version line is automatically added during release by this
      # method we can check for new bullet points since the last release.
      if content.scan(/# Machinery .*$\n+## Version /).empty?
        content = content.sub(
          /\n+/, "\n\n\n## Version #{@options[:version]} - #{@release_time} - #{@mail}\n\n"
        )
        File.write(file, content)
      end
    end
  end

  def add_default_rpm_changes_entry
    file = "RPM_CHANGES"
    content = File.read(file)

    regex = /(Machinery .{0,7}RPM Changelog).*?(\*|\n#)/m
    content.sub!(regex, "\\1\n\n* update to version #{@options[:version]}\n\\2")

    File.write(file, content)
  end

  def commit
    # Build gem and send everything to IBS
    Rake::Task["osc:commit"].invoke

    # Set and commit git tag
    Cheetah.run "git", "commit", "-a", "-m", "package #{@options[:version]}"
    Cheetah.run "git", "tag", "-a", @tag, "-m", "Tag version #{@options[:version]}"
    Cheetah.run "git", "push"
    Cheetah.run "git", "push", "--tags"
  end

  def create_rpm_header(version, time, mail)
    header  = "-------------------------------------------------------------------\n"
    header += time + " - " + mail + "\n\n"
    header
  end
end
