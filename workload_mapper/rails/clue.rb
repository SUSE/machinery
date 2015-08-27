if system.runs_service?("apache2") && system.has_file?("/usr/bin/rails")
  apache_vhosts = system["unmanaged_files"].files.select { |f| /vhosts\.d/ =~ f.name }.map(&:name)
  apache_vhosts.each do |vhost|
    rails_env = system.read_config(vhost, "PassengerAppEnv")
    rails_public = system.read_config(vhost, "DocumentRoot")

    if !rails_env.empty? && /public/.match(rails_public)
      identify "rails", "web"
      parameter "ports", ["3000:3000"]
      parameter "links", ["db"]
      rails_root = rails_public.gsub(/\/public/, "")
      extract rails_root, "data"
      break # for now we only handle the first rails app that was found
    end
  end
end
