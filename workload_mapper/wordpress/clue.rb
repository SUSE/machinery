if system.runs_service?("apache2")
  apache_vhosts = system["unmanaged_files"].files.select { |f| /vhosts\.d/ =~ f.name }.map(&:name)
  apache_vhosts.each do |vhost|
    root = system.read_config(vhost, "DocumentRoot")
    if system.has_file?(File.join(root, "wp-config.php"))
      identify "wordpress", "web"
      parameter "ports", ["8000:8000"]
      parameter "links", ["db"]
      extract File.join(root, ""), "data"
      break # for now we only handle the first wordpress that was found
    end
  end
end
