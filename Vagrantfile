# -*- mode: ruby -*-
# # vi: set ft=ruby :

update_channel = "stable"

num_etcds = 1
num_masters = 1
num_workers = 1
num_ingress = 1

etcd_image = "quay.io/coreos/etcd:v3.2.4"
namerd_image = "buoyantio/namerd:1.3.5"
vault_image = "vault:0.9.0"
linkerd_image = "linkerd/linkerd-tcp:0.1.1"
hyperkube_image = "quay.io/coreos/hyperkube:v1.9.2_coreos.0"
pause_image = "gcr.io/google_containers/pause-amd64:3.1"
calico_node_image = "quay.io/calico/node:v3.0.1"
calico_cni_image = "quay.io/calico/cni:v2.0.0"
calico_kube_controller_image = "quay.io/calico/kube-controllers:v2.0.0"
coreDNS_image = "coredns/coredns:1.0.4"
helm_image = "lachlanevenson/k8s-helm:v2.7.2"

instance_master_prefix = "master"
instance_worker_prefix = "worker"
instance_etcd_prefix = "etcd"
instance_ingress_prefix = "ingress"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.box = "coreos-%s" % update_channel
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % update_channel
  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
    v.cpus = 4
    v.memory = 2156
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (1..num_etcds).each do |i|
    vm_name = "%s-%02d" % [instance_etcd_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+100}"
      host.vm.network :private_network, ip: ip
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      host.vm.provision "docker" do |d|
        d.pull_images "%s" % etcd_image
        d.pull_images "%s" % namerd_image
        d.pull_images "%s" % vault_image
      end
      config.vm.synced_folder ".", "/home/core/vagrant", id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      host.vm.provision :shell, :inline => "cd /home/core/vagrant; sudo /home/core/vagrant/etcdUp.sh"
    end
  end

  (1..num_masters).each do |i|
    vm_name = "%s-%02d" % [instance_master_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+50}"
      host.vm.network :private_network, ip: ip
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      host.vm.provision "docker" do |d|
        d.pull_images "%s" % linkerd_image
        d.pull_images "%s" % hyperkube_image
        d.pull_images "%s" % pause_image
        d.pull_images "%s" % calico_node_image
        d.pull_images "%s" % calico_cni_image
        d.pull_images "%s" % calico_kube_controller_image
        d.pull_images "%s" % coreDNS_image
        d.pull_images "%s" % helm_image
      end
      config.vm.synced_folder ".", "/home/core/vagrant", id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      host.vm.provision :shell, :inline => "cd /home/core/vagrant; sudo /home/core/vagrant/masterUp.sh"
    end
  end

  (1..num_workers).each do |i|
    vm_name = "%s-%02d" % [instance_worker_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+150}"
      host.vm.network :private_network, ip: ip
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      host.vm.provision "docker" do |d|
        d.pull_images "%s" % linkerd_image
        d.pull_images "%s" % hyperkube_image
        d.pull_images "%s" % calico_node_image
        d.pull_images "%s" % calico_cni_image
        d.pull_images "%s" % calico_kube_controller_image
      end
      config.vm.synced_folder ".", "/home/core/vagrant", id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      host.vm.provision :shell, :inline => "cd /home/core/vagrant; sudo /home/core/vagrant/workerUp.sh"
    end
  end

  (1..num_ingress).each do |i|
    vm_name = "%s-%02d" % [instance_ingress_prefix, i]
    config.vm.define vm_name do |host|
      host.vm.hostname = vm_name

      ip = "172.17.8.#{i+200}"
      host.vm.network :private_network, ip: ip
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr flush dev eth1"
      host.vm.provision :shell, :inline => "sudo /usr/bin/ip addr add #{ip}/24 dev eth1"
      host.vm.provision "docker" do |d|
        d.pull_images "%s" % linkerd_image
        d.pull_images "%s" % hyperkube_image
        d.pull_images "%s" % calico_node_image
        d.pull_images "%s" % calico_cni_image
        d.pull_images "%s" % calico_kube_controller_image
      end
      config.vm.synced_folder ".", "/home/core/vagrant", id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      host.vm.provision :shell, :inline => "cd /home/core/vagrant; sudo /home/core/vagrant/ingressUp.sh"
    end
  end

    config.vm.post_up_message = "Vagrant has finished"
end
