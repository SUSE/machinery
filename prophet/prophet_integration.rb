#!/usr/bin/env ruby

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

require "prophet"
require "logger"
require "yaml"

Prophet.setup do |config|
  # Setup custom logger.
  config.logger = log = Logger.new(STDOUT)
  log.level = Logger::INFO

  CONFIG_FILE = "config/options-local.yml"
  if File.exists?(CONFIG_FILE)
    options = YAML.load_file(CONFIG_FILE)
    # The GitHub (GH) username/password to use for commenting on a successful run.
    config.username = options["default"]["git_username"]
    config.password = options["default"]["git_password"]
  end
  config.status_context = "prophet/integration"
  config.disable_comments = true

  # Add Jenkins URL if available.
  jenkins_url = `echo $BUILD_URL`.chomp
  unless jenkins_url.empty?
    config.status_target_url = "#{jenkins_url}console"
  end

  # Specify when to run your code.
  # By default your code will run every time either the pull request or its
  # target (i.e. master) changes.
  config.rerun_on_source_change = true
  config.rerun_on_target_change = true

  # Add custom messages for comments and statuses.
  config.status_pending = "Tests are still running."
  config.status_success = "Tests are passing."
  config.status_failure = "Tests are failing."

  @run_main_jenkins_job = false

  # If you need to make some system calls before looping through the pull requests,
  # you specify them here. This block will only be executed once and defaults to an
  # empty block.
  # config.preparation do
  #   # Example: Setup jenkins.
  #   `rake -f /usr/lib/ruby/gems/1.9.1/gems/ci_reporter-1.7.0/stub.rake`
  #   `rake ci:setup:testunit`
  # end

  # Finally, specify which code to run. (Defaults to `rake`.)
  # NOTE: If you don't set config.success manually to a boolean value,Prophet
  # will try to determine it by looking at whether the last system call returned
  # 0 (= success).
  if ENV["PROPHET_TRIGGER_RUN"]
    config.execution do
      config.status_context = "prophet/trigger"
      @run_main_jenkins_job = true
      config.success = ($? == 0)
    end
  else
    config.execution do
      log.info "Running tests ..."

      system(
        "cd ..; (bundle check || sudo bundle install) && rake rpm:build &&" \
          " rspec spec/integration --tag=ci"
      )
      config.success = ($? == 0)

      log.info "Tests are #{config.success ? "passing" : "failing"}."
    end
  end
end

Prophet.run

if @run_main_jenkins_job
  if File.exists?(CONFIG_FILE)
    options = YAML.load_file(CONFIG_FILE)
    crumb = options["default"]["crumb"]
    token = options["default"]["token"]
  end
  system("curl -H #{crumb} -X POST https://ci.opensuse.org/view/Machinery/job/machinery-prophet-integration/build --data token=#{token}")
end
