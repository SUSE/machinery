# encoding: utf-8

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

require_relative "lib/constants"
require_relative "lib/version"
require_relative "tools/release"
require_relative "tools/upgrade_test_descriptions"
require_relative "lib/machinery"
require_relative "tools/inspector_files"
require "rspec/core/rake_task"
require "cheetah"
require "packaging"

desc "Run RSpec code examples in spec/unit"
RSpec::Core::RakeTask.new("spec:unit") do |t|
  t.exclude_pattern = "spec/integration/**/*"
end

desc "Run RSpec code examples in spec/integration"
RSpec::Core::RakeTask.new("spec:integration") do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

desc "Run acceptance RSpec code examples in spec/integration"
RSpec::Core::RakeTask.new("spec:integration:acceptance") do |t|
  ENV["TESTGROUP"] = "acceptance"
  t.pattern = "spec/integration/**/*_spec.rb"
end

desc "Run minimal RSpec code examples in spec/integration"
RSpec::Core::RakeTask.new("spec:integration:minimal") do |t|
  ENV["TESTGROUP"] = "minimal"
  t.pattern = "spec/integration/**/*_spec.rb"
end

desc "Run full RSpec code examples in spec/integration"
RSpec::Core::RakeTask.new("spec:integration:full") do |t|
  ENV["TESTGROUP"] = "full"
  t.pattern = "spec/integration/**/*_spec.rb"
end

desc "Run RSpec code examples"
task :spec => ["spec:unit", "spec:integration"]

# Needed by packaging_rake_tasks.
desc 'Alias for "spec:unit"'
task :test => ["spec:unit"]

desc "Run RSpec code examples in spec/tools"
RSpec::Core::RakeTask.new("spec:tools") do |t|
  t.pattern = "spec/tools/**/*_spec.rb"
end

Packaging.configuration do |conf|
  conf.obs_api = "https://api.opensuse.org"
  conf.obs_project = "systemsmanagement:machinery"
  conf.package_name = "machinery"
  conf.obs_target = "openSUSE_13.2"
  conf.version = Machinery::VERSION

  #lets ignore license check for now
  conf.skip_license_check << /.*/
end

namespace :man_pages do
  desc 'Build man page(s)'
  task :build do
    puts "  Building man pages"
    manpage = ""
    Inspector.all_scopes.each do |scope|
      manpage += "* #{scope}\n\n"
      manpage += File.read("plugins/#{scope}/#{scope}.md")
      manpage += "\n"
    end
    manpage += "\n"
    File.write("man/generated/machinery_main_scopes.1.md", manpage)

    system <<-EOF
      cat man/machinery_main_general.1.md man/generated/machinery_main_scopes.1.md \
        man/machinery_main_usecases.1.md man/machinery-*.1.md \
        man/machinery_footer.1.md  > man/generated/machinery.1.md
    EOF
    system "sed -i '/<!--.*-->/d' man/generated/machinery.1.md"
    system "ronn man/generated/machinery.1.md"
    system "gzip -f man/generated/*.1"
    # Build man page for website (manual.html)
    system "ronn -f man/generated/machinery.1.md"
    system "man/generate_man"
  end
end

# Disable packaging_tasks' tarball task. We package a gem, so we don't have to
# put the sources into IBS. Instead we build the gem in the tarball task
Rake::Task[:tarball].clear
task :tarball => ["man_pages:build"] do
  Cheetah.run "gem", "build", "machinery.gemspec"
  FileUtils.mv Dir.glob("machinery-*.gem"), "package/"
end

namespace :rpm do
  desc 'Build RPM of current version'
  task :build, [:api, :project, :target] do |task, args|
    # make sure the helper version is up to date
    Dir.chdir(File.join(Machinery::ROOT, "machinery-helper")) do
      Cheetah.run("rake", "build")
    end

    if args[:api] && args[:project] && args[:target]
      Packaging.configuration do |conf|
        conf.obs_api = args[:api]
        conf.obs_project = args[:project]
        conf.obs_target = args[:target]
      end
    end

    # This task builds unreleased versions of the RPM, so we don't want to
    # bump and commit the version each time. Instead we just set the version
    # temporarily and revert the change afterwards. That causes the
    # check:committed check which is triggered by osc:build to fail, though,
    # so we clear it instead.
    Rake::Task["check:committed"].clear
    Rake::Task["check:syntax"].clear

    # We don't want the unit tests to be called each time the package is
    # build since building is also required for the integration tests.
    # This allows running the integration tests on a work-in-progress code
    # base even when the unit tests are failing.
    Rake::Task["package"].prerequisites.delete("test")

    skip_rpm_cleanup = (ENV["SKIP_RPM_CLEANUP"] == "true")
    release = Release.new(skip_rpm_cleanup: skip_rpm_cleanup)
    release.build_local
  end
end

desc "Release a new version ('type' is either 'major', 'minor 'or 'patch')"
task :release, [:type] do |task, args|
  unless ["major", "minor", "patch"].include?(args[:type])
    puts "Please specify a valid release type (major, minor or patch)."
    exit 1
  end

  # make sure the helper version is up to date
  Dir.chdir(File.join(Machinery::ROOT, "machinery-helper")) do
    Cheetah.run("rake", "build")
  end

  new_version = Release.generate_release_version(args[:type])
  release = Release.new(version: new_version)

  # Check syntax, git and CI state
  Rake::Task['check:committed'].invoke
  Rake::Task['check:syntax'].invoke
  release.check

  release.publish
  release.publish_man_page
end

desc "Build files in destination directory with scope information for integration tests"

# This command creates reference data for integration tests
# by inspecting existing machines.
# Therefor it generates files with information of each scope.

task :inspector_files, [:ip_adress, :destination] do |task, args|
  ip_adress = args[:ip_adress]
  distri = args[:destination]
  CreateScopeInfoTestData.inspect_system(ip_adress)
  CreateScopeInfoTestData.write_inspector_file(distri)
end

desc "Upgrade machinery unit/integration test descriptions"
task :upgrade_test_descriptions do
  DESCRIPTIONS_PATH = File.join(Machinery::ROOT, "spec", "data", "descriptions")
  # we don't want to upgrade format_vX, invalid-json, so we list the ones
  # we want to upgrade here
  descriptions = [
    "opensuse131-build",
    "validation-error"
  ]

  upgrade_descriptions(DESCRIPTIONS_PATH, descriptions)
  upgrade_descriptions(File.join(DESCRIPTIONS_PATH, "jeos"))
  upgrade_descriptions(File.join(DESCRIPTIONS_PATH, "validation"))
  upgrade_descriptions(File.join(Machinery::ROOT, "spec/data/schema/"),
    ["faulty_description", "valid_description"]
  )
  update_json_format_version(
    File.join(Machinery::ROOT, "spec/data/schema/validation_error/config_files")
  )
  update_json_format_version(
    File.join(Machinery::ROOT, "spec/data/schema/validation_error/unmanaged_files")
  )
end

desc "Generate Machinery Test Matrix as a Spreadsheet"
task "matrix:spreadsheet" do
  begin
    require_relative "tools/support_matrix/lib/support_matrix"
  rescue LoadError => e
    puts <<-EOF
      Error: #{e.message}

      You can solve this issue by:

        1) running `bundle exec rake matrix:spreadsheet` or
        2) by installing the gems binstubs `bundle install --binstubs`

    EOF
  end
  sources = File.join(Machinery::ROOT, "spec", "definitions", "support")
  file = SupportMatrix.new(sources, OdsFormatter.new).write(sources)
  puts "File #{File.absolute_path(file)} was created"
end

desc "Generate Machinery Test Matrix as a PDF file"
task "matrix:pdf" do
  begin
    require_relative "tools/support_matrix/lib/support_matrix"
  rescue LoadError => e
    puts <<-EOF
      Error: #{e.message}

      You can solve this issue by:

        1) running `bundle exec rake matrix:spreadsheet` or
        2) by installing the gems binstubs `bundle install --binstubs`

    EOF
  end
  sources = File.join(Machinery::ROOT, "spec", "definitions", "support")
  file = SupportMatrix.new(sources, PdfFormatter.new).write(sources)
  puts "File #{File.absolute_path(file)} was created"
end
