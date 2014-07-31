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

class KiwiExportTask
  def export(description, kiwi_dir, options)
    if File.exists?(kiwi_dir)
      if options[:force]
        FileUtils.rm_r(kiwi_dir)
      else
        raise Machinery::Errors::KiwiExportFailed.new(
          "The output directory '#{kiwi_dir}' already exists." \
          " You can force overwriting it with the '--force' option."
        )
      end
    end

    FileUtils.mkdir_p(kiwi_dir) unless Dir.exists?(kiwi_dir)

    config = KiwiConfig.new(description)
    config.write(kiwi_dir)
  end
end
