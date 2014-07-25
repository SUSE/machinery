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

class LocalSystem < System
  def requires_root?
    true
  end

  def run_command(*args)
    if args.last.is_a?(Hash) && args.last[:disable_logging]
      cheetah_class = Cheetah
    else
      cheetah_class = LoggedCheetah
    end
    with_c_locale do
      cheetah_class.run(*args)
    end
  end

  # Retrieves files specified in filelist from the local system and raises an
  # Machinery::RsyncFailed exception when it's not successful. Destination is
  # the directory where to put the files.
  def retrieve_files(filelist, destination)
    begin
      LoggedCheetah.run("rsync",  "--chmod=go-rwx", "--files-from=-", "/", destination, :stdout => :capture, :stdin => filelist.join("\n") )
    rescue Cheetah::ExecutionFailed => e
      raise Machinery::RsyncFailed.new(
      "Could not rsync files from localhost. \n" \
      "Error: #{e}\n" \
      "If you lack read permissions on some files you may want to retry as user root or specify\n" \
      "the fully qualified host name instead of localhost in order to connect as root via ssh."
    )
    end
  end

  private

  def with_c_locale(&block)
    with_env "LC_ALL" => "C", &block
  end

  def with_env(env)
    # ENV isn't a Hash, but a weird Hash-like object. Calling #to_hash on it
    # will copy its items into a newly created Hash instance. This approach
    # ensures that any modifications of ENV won't affect the stored value.
    saved_env = ENV.to_hash
    begin
      ENV.replace(saved_env.merge(env))
      yield
    ensure
      ENV.replace(saved_env)
    end
  end

end
