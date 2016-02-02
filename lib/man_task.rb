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

class ManTask
  def self.compile_documentation
    docs = Inspector.all_scopes.map do |scope|
      scope_doc = "* #{scope}\n\n"
      scope_doc += YAML.load_file(
        File.join(Machinery::ROOT, "plugins/#{scope}/#{scope}.yml")
      )[:description]
      scope_doc + "\n"
    end.join
    File.write("manual/docs/machinery_main_scopes.1.md", docs)
    Dir.chdir(File.join(Machinery::ROOT, "manual")) do
      Cheetah.run("mkdocs", "build")
    end
  end

  def man(options)
    if options[:html]
      man_html(options)
    else
      man_system
    end
  end

  def man_system
    LocalSystem.validate_existence_of_package("man")
    system("man", File.join(Machinery::ROOT, "man/generated/machinery.1.gz"))
  end

  def man_html(options)
    unless File.exist?(File.join(Machinery::ROOT, "manual/site"))
      Machinery::Ui.warn(
        "The documentation was not generated yet. Please make sure that `mkdocs` is installed on " \
        "your system and run `rake man_pages:compile_documentation` from the machinery directory."
      )
      return
    end

    LocalSystem.validate_existence_of_command("xdg-open", "xdg-utils")

    url = "http://#{options[:ip]}:#{options[:port]}/site/docs/index.html"

    Machinery::Ui.use_pager = false
    Machinery::Ui.puts <<EOF
Trying to start a web server for serving the documentation on #{url}.

The server can be closed with Ctrl+C.
EOF

    server = Html.run_server(SystemDescriptionStore.new, port: options[:port], ip: options[:ip]) do
      LoggedCheetah.run("xdg-open", url)
    end

    server.join # Wait until the user cancelled the blocking webserver
  end
end
