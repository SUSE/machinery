Veewee::Definition.declare({
  :cpu_count => '2',
  :memory_size=> '384',
  :disk_size => '20280',
  :disk_format => 'VDI',
  :hostiocache => 'off',
  :os_type_id => 'OpenSUSE_64',
  :iso_file => "openSUSE-13.1-DVD-x86_64.iso",
  :iso_src => "http://download.opensuse.org/distribution/13.1/iso/openSUSE-13.1-DVD-x86_64.iso",
  :iso_md5 => "1096c9c67fc8a67a94a32d04a15e909d",
  :iso_download_timeout => "1000",
  :boot_wait => "10",
  :boot_cmd_sequence => [
    '<Esc><Enter>',
    'linux',
    ' netdevice=eth0',
    ' netsetup=dhcp',
    ' instmode=dvd',
    ' textmode=1',
    ' autoyast=http://%IP%:8888/autoinst.xml',
    '<Enter>'
   ],
  :ssh_login_timeout => "10000",
  :ssh_user => "vagrant",
  :ssh_password => "vagrant",
  :ssh_key => "",
  :ssh_host_port => "7222",
  :ssh_guest_port => "22",
  :sudo_cmd => "echo '%p'|sudo -S sh '%f'",
  :shutdown_cmd => "shutdown -P now",
  :postinstall_files => [ "postinstall.sh", "postinstall_machinery.sh"],
  :postinstall_timeout => "10000",
  :hooks => {
    # Before starting the build we spawn a webrick webserver which serves the
    # autoyast profile to the installer. veewee's built in webserver solution
    # doesn't work reliably with autoyast due to some timing issues.
    :before_create => Proc.new do
      path = "#{Dir.pwd}/definitions/#{definition.box.name}"
      Thread.new { WEBrick::HTTPServer.new(:Port => 8888, :DocumentRoot => path).start }
    end
  }
})
