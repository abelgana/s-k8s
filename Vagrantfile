# -*- mode: ruby -*-
# # vi: set ft=ruby :

update_channel = "stable"

num_masters = 1
num_etcds = 1
num_workers = 1

instance_master_prefix = "master"
instance_worker_prefix = "worker"
instance_etcd_prefix = "etcd"

Vagrant.configure("2") do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false
  config.vm.box = "coreos-%s" % update_channel
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % update_channel
  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS Container Linux, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
    v.cpus = 4
    v.memory = 4096
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

    # Set up each box
  (1..num_masters).each do |i|
    vm_name = "%s-%02d" % [instance_master_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+50}"
      host.vm.network :private_network, ip: ip
      # Workaround VirtualBox issue where eth1 has 2 IP Addresses at startup
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      config.vm.synced_folder ".", "/home/core/vagrant"
      #config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
    end
  end

  (1..num_etcds).each do |i|
    vm_name = "%s-%02d" % [instance_etcd_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+100}"
      host.vm.network :private_network, ip: ip
      # Workaround VirtualBox issue where eth1 has 2 IP Addresses at startup
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      config.vm.synced_folder ".", "/home/core/vagrant" , type: "rsync"
      #config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
    end
  end

  (1..num_workers).each do |i|
    vm_name = "%s-%02d" % [instance_worker_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+150}"
      host.vm.network :private_network, ip: ip
      # Workaround VirtualBox issue where eth1 has 2 IP Addresses at startup
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      config.vm.synced_folder ".", "/home/core/vagrant", type: "rsync"
      #config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
    end
  end

    config.vm.post_up_message = "Vagrant has finished"
end
