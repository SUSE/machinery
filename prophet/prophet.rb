#!/usr/bin/env ruby

# Copyright (c) 2013-2014 SUSE LLC
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

require 'prophet'
require 'logger'
require 'yaml'

def run_tests(test_runs_success, config, log)
  yield
  test_runs_success << true
rescue Cheetah::ExecutionFailed => e
  test_runs_success << false
  config.comment_failure += e.message
  log.error e.message
  log.error "\n\nStandard output:\n #{e.stdout}\n"
  log.error "\n\nError output:\n #{e.stderr}\n"
end

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

    # The Git credentials for commenting on failing runs (can be the same as above).
    # NOTE: If you specify two different accounts with different avatars, it's
    # a lot easier to spot failing test runs at first glance.
    config.username_fail = options["default"]["git_username_fail"]
    config.password_fail = options["default"]["git_password_fail"]
  end

  # Add Jenkins URL if available.
  jenkins_url = `echo $BUILD_URL`.chomp
  unless jenkins_url.empty?
    message = "Prophet reports failure.\n#{jenkins_url}console"
    message += "\nIf the given link has expired, you can force a Prophet rerun by just deleting this comment."
    config.comment_failure = message
  end

  # Specify when to run your code.
  # By default your code will run every time either the pull request or its
  # target (i.e. master) changes.
  config.rerun_on_source_change = true
  config.rerun_on_target_change = true

  # Add custom messages for comments and statuses.
  config.comment_success = 'Well Done! Your tests are still passing.'
  config.status_pending = 'Tests are still running.'
  config.status_success = 'Tests are passing.'
  config.status_failure = 'Tests are failing.'

  # If you need to make some system calls before looping through the pull requests,
  # you specify them here. This block will only be executed once and defaults to an
  # empty block.
  #config.preparation do
  #  # Example: Setup jenkins.
  #  `rake -f /usr/lib/ruby/gems/1.9.1/gems/ci_reporter-1.7.0/stub.rake`
  #  `rake ci:setup:testunit`
  #end

  # Finally, specify which code to run. (Defaults to `rake`.)
  # NOTE: If you don't set config.success manually to a boolean value,Prophet
  # will try to determine it by looking at whether the last system call returned
  # 0 (= success).
  config.execution do
    log.info 'Running tests ...'

    system("cd ..; (bundle check || sudo bundle install) && rake spec:unit")
    config.success = ($? == 0)

    log.info "Tests are #{config.success ? 'passing' : 'failing'}."
  end

end

Prophet.run
