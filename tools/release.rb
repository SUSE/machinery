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
  include ReleaseChecks

  RPM_CHANGES_FILE = File.join(Machinery::ROOT, "package/machinery.changes")
  CHANGELOG_FILES = [
    File.join(Machinery::ROOT, "NEWS"),
    File.join(Machinery::ROOT, "RPM_CHANGES")
  ]

  def initialize(opts = {})
    @options = {
      version: generate_development_version,
      skip_rpm_cleanup: false
    }.merge(opts)
    @release_version = @options[:version]
    @tag = "v#{@release_version}"
    @release_time = Time.now.strftime("%a %b %d %H:%M:%S %Z %Y")
    @mail = Cheetah.run(["git", "config", "user.email"], stdout: :capture).chomp
    @gemspec = Gem::Specification.load("machinery.gemspec")
  end

  def prepare
    clean_up_tmp
    remove_old_releases(skip_rpm_cleanup: @options[:skip_rpm_cleanup])
    set_version
    generate_specfile
    copy_rpmlintrc
    add_default_rpm_changes_entry
    generate_changelog
  end

  # Update the version file, generate a changelog and RPM specfile and build
  # an RPM using osc
  def build_local
    prepare

    Rake::Task["osc:build"].invoke

    # Collect built RPMs in package/, e.g. so that jenkins can collect them
    output_dir = File.join("/var/tmp", obs_project, build_dist)
    FileUtils.cp Dir.glob("#{output_dir}/*.rpm"), "package/"
  ensure
    # revert the version and changelog changes
    Cheetah.run "git", "checkout", File.join(Machinery::ROOT, "lib/version.rb")
    Cheetah.run "git", "checkout", File.join(Machinery::ROOT, "RPM_CHANGES")
  end

  # Commit version changes, tag release and push changes upstream.
  def publish
    prepare
    finalize_news_file

    # Build gem and send everything to IBS
    Rake::Task["osc:commit"].invoke

    commit
  end

  # Calculates the next version number according to the release type (:major, :minor or :patch)
  def self.generate_release_version(release_type)
    current_version = Machinery::VERSION
    major, minor, patch = current_version.scan(/(\d+)\.(\d+)\.(\d+)/).first.map(&:to_i)

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

  def publish_man_page
    Cheetah.run("git", "checkout", "gh-pages")
    Cheetah.run("git", "pull")
    FileUtils.cp("man/generated/manual.html", "manual.html")
    if !Cheetah.run("git", "ls-files", "-m", stdout: :capture).empty?
      puts("Publishing man page to website...")
      Cheetah.run(
        "git", "commit", "-m", "Update man page for release #{@options[:version]}", "manual.html"
      )

      Cheetah.run("git", "push")
    else
      puts("The man page hasn't changed, no update of the website required.")
    end
    Cheetah.run("git", "checkout", "master")
  end

  def publish_gem
    Dir.chdir(File.join(Machinery::ROOT, "package")) do
      gem = Dir.glob("*.gem").first
      if gem
        puts("Publishing gem to rubygems.org")
        Cheetah.run("gem", "push", gem)
      else
        raise("There is no gem to publish")
      end
    end
  end

  private

  def remove_old_releases(skip_rpm_cleanup: false)
    if skip_rpm_cleanup
      FileUtils.rm Dir.glob(File.join(Machinery::ROOT, "package/*.gem"))
    else
      FileUtils.rm Dir.glob(File.join(Machinery::ROOT, "package/*"))
    end
  end

  def clean_up_tmp
    output_dir = File.join("/var/tmp", obs_project, build_dist)
    FileUtils.rm Dir.glob("#{output_dir}/*.rpm")
  end

  def set_version
    Dir.chdir(Machinery::ROOT) do
      Cheetah.run "sed", "-i", "s/VERSION.*=.*/VERSION = \"#{@release_version}\"/", "lib/version.rb"
    end
  end

  def generate_specfile
    Dir.chdir(Machinery::ROOT) do
      erb = ERB.new(File.read("machinery.spec.erb"), nil, "-")
      env = SpecTemplate.new(@release_version, @gemspec)

      File.open("package/machinery.spec", "w+") do |spec_file|
        spec_file.puts erb.result(env.instance_eval { binding })
      end
    end
  end

  def copy_rpmlintrc
    Dir.chdir(Machinery::ROOT) do
      FileUtils.cp "machinery-rpmlintrc", "package/machinery-rpmlintrc"
    end
  end

  def generate_changelog
    changes = { @release_version => create_rpm_header(@release_version, @release_time, @mail) }
    news = { @release_version => "" }
    CHANGELOG_FILES.each do |file|
      version = @release_version
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

    File.write(RPM_CHANGES_FILE, changelog)
  end

  def finalize_news_file
    CHANGELOG_FILES.each do |file|
      content = File.read(file)
      # All changes for the next release are directly added below the headline
      # by the developers without adding a version line.
      # Since the version line is automatically added during release by this
      # method we can check for new bullet points since the last release.
      if content.scan(/# Machinery .*$\n+## Version /).empty?
        content = content.sub(/\n+/, "\n\n\n## Version #{@release_version} - #{@release_time} " \
          "- #{@mail}\n\n")
        File.write(file, content)
      end
    end
  end

  def add_default_rpm_changes_entry
    file = File.join(Machinery::ROOT, "RPM_CHANGES")
    content = File.read(file)

    regex = /(Machinery RPM Changelog).*?(\*|\n#)/m
    content.sub!(regex, "\\1\n\n* update to version #{@release_version}\n\\2")

    File.write(file, content)
  end

  def commit
    Cheetah.run "git", "commit", "-a", "-m", "package #{@release_version}"
    Cheetah.run "git", "tag", "-a", @tag, "-m", "Tag version #{@release_version}"
    Cheetah.run "git", "push"
    Cheetah.run "git", "push", "--tags"
  end

  def generate_development_version
    # The development version RPMs have the following version number scheme:
    # <base version>.<timestamp><os>git<short git hash>
    timestamp = Time.now.strftime("%Y%m%dT%H%M%SZ")
    commit_id = Cheetah.run("git", "rev-parse", "--short", "HEAD", stdout: :capture).chomp

    "#{Machinery::VERSION}.#{timestamp}#{build_dist.gsub(/[._]/, "")}git#{commit_id}"
  end

  def create_rpm_header(version, time, mail)
    header  = "-------------------------------------------------------------------\n"
    header += time + " - " + mail + "\n\n"
    header
  end
end
