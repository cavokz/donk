# -*- mode: ruby -*-
# vi: set ft=ruby :

# Resource:
#  - https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/
#  - https://www.itwonderlab.com/en/ansible-kubernetes-vagrant-tutorial/
#  - https://www.tigera.io/learn/guides/kubernetes-networking/kubernetes-cni/
#  - https://kubevious.io/blog/post/comparing-kubernetes-container-network-interface-cni-providers
#  - https://github.com/actions/virtual-environments/issues/2999
#  - https://github.com/actions/virtual-environments/issues/433
#  - https://github.com/actions/virtual-environments/issues/183
#  - https://blog.wikichoon.com/2016/01/qemusystem-vs-qemusession.html

N = 2
NET = "192.168.56"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"

  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.cpus = 2
    virtualbox.memory = 4096
  end

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 2
    libvirt.memory = 4096

    libvirt.uri = "qemu:///session"
    libvirt.driver = "qemu"
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision "shell",
    inline: "apt-get install --yes python3-apt"

  (0..N-1).each do |i|
    config.vm.define "node-#{i}" do |node|
      node_ip = "#{NET}.#{100 + i}"

      #node.vm.network "private_network", ip: node_ip
      node.vm.network "public_network", :type => "user"
      node.vm.hostname = "node-#{i}"

      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "k8s-node.yaml"
        ansible.extra_vars = {
          node_ip: node_ip,
        }
      end

      if i == 0
        node.vm.provision "ansible" do |ansible|
          ansible.playbook = "k8s-controller.yaml"
          ansible.extra_vars = {
            node_ip: node_ip,
          }
        end
      end
    end
  end
end
