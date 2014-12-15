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

class ExportTask
  def initialize(exporter)
    @exporter = exporter
  end

  def export(output_dir, options)
    if File.exists?(output_dir)
      if options[:force]
        FileUtils.rm_r(output_dir)
      else
        raise Machinery::Errors::ExportFailed.new(
          "The output directory '#{output_dir}' already exists." \
          " You can force overwriting it with the '--force' option."
        )
      end
    end

    FileUtils.mkdir_p(output_dir, mode: 0700) if !Dir.exists?(output_dir)

    @exporter.write(output_dir)
  end
end
