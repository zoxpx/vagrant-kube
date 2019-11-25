# -*- mode: ruby -*-
# vim:ft=ruby:sw=3:et:

vm_nodes = {            # EDIT to specify VM node names, and their private IP (vboxnet#)
   'kb-master' => "192.168.56.80",
   'kb-node1' => "192.168.56.81",
   'kb-node2' => "192.168.56.82",
   'kb-node3' => "192.168.56.83",
}
# EDIT or specify ENV variable to define OS-Type (see `vm_conf` below)
ostype = ENV['KUBE_OSTYPE'] || 'ubuntu16'
#ostype = ENV['KUBE_OSTYPE'] || 'centos7'
#ostype = ENV['KUBE_OSTYPE'] || 'bento16'

# VM config, format: <type-label> => [ 0:vagrant-box, 1:vm-net-iface, 2:vm-disk-controller, 3:vm-start-port, 4:vm-drives-map ]
# see https://app.vagrantup.com/boxes/search for more VM images (ie. "box-names")
vm_conf = {
   'ubuntu16' => [ 'ubuntu/xenial64', 'enp0s8', 'SCSI', 2, { "sdc" => 15*1024, "sdd" => 20*1024 } ],
   'ubuntu18' => [ 'ubuntu/bionic64', 'enp0s8', 'SCSI', 2, { "sdc" => 15*1024, "sdd" => 20*1024 } ],
   'bento16' => [ 'bento/ubuntu-16.04', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'centos7'  => [ 'centos/7', 'eth1', 'IDE', 1, { "sdb" => 20*1024 } ],
   'fedora29'  => [ 'generic/fedora29', 'eth1', 'IDE Controller', 1, { "sdb" => 20*1024 } ],
   'rhel7'  => [ 'generic/rhel7', 'eth1', 'IDE Controller', 1, { "sdb" => 20*1024 } ],
   # -- NOT supported for Kubernetes:
   'ubuntu14' => [ 'ubuntu/trusty64', 'eth1', 'SATAController', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'debian8'  => [ 'debian/jessie64', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'debian9'  => [ 'debian/stretch64', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
}

# (internal variables)
mybox, myvmif, mycntrl, myport, extra_disks = vm_conf[ostype]
mystorage = "/dev/"+extra_disks.keys().join(",/dev/")
k8s_master_host, k8s_master_ip = vm_nodes.first()
k8s_cidr, k8s_token, etc_hosts = nil, "030ffd.5d7a97b7e0d23ba9", ""
unless k8s_master_ip.nil?
   t = k8s_master_ip.split('.'); t[3] = "0/24"; k8s_cidr = t.join('.')     # 192.168.56.70 -> 192.168.56.0/24
end
vm_nodes.each do |host,ip|
   unless ip.nil?
      etc_hosts += "\n#{ip}\t#{host}"
   end
end

#
# VAGRANT SETUP
#
Vagrant.configure("2") do |config|

   vm_nodes.each do |host,ip|
      config.vm.define "#{host}" do |node|

         node.vm.box = "#{mybox}"
         node.vm.hostname = "#{host}"
         unless ip.nil?
            node.vm.network "private_network", ip: "#{ip}", :netmask => "255.255.255.0"
         else
            node.vm.network "public_network", bridge: "eth0", use_dhcp_assigned_default_route: true
         end

         node.vm.provider "virtualbox" do |v|
            v.gui = false
            v.memory = 4096

            # Extra customizations
            v.customize 'pre-boot', ["modifyvm", :id, "--cpus", "2"]
            v.customize 'pre-boot', ["modifyvm", :id, "--chipset", "ich9"]
            v.customize 'pre-boot', ["modifyvm", :id, "--audio", "none"]
            v.customize 'pre-boot', ["modifyvm", :id, "--usb", "off"]
            v.customize 'pre-boot', ["modifyvm", :id, "--accelerate3d", "off"]
            v.customize 'pre-boot', ["storagectl", :id, "--name", "#{mycntrl}", "--hostiocache", "on"]

            # force Virtualbox to sync the time difference w/ threshold 10s (defl was 20 minutes)
            v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000 ]

            # Net boot speedup (see https://github.com/mitchellh/vagrant/issues/1807)
            v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

            if defined?(extra_disks)
               # NOTE: If you hit errors w/ extra disks provisioning, you may need to run "Virtual
               # Media Manager" via VirtualBox GUI, and manually remove $host_sdX drives.
               port = myport
               extra_disks.each do |hdd, size|
                  vdisk_name = ".vagrant/#{host}_#{hdd}.vdi"
                  unless File.exist?(vdisk_name)
                     v.customize ['createhd', '--filename', vdisk_name, '--size', "#{size}"]
                  end
                  v.customize ['storageattach', :id, '--storagectl', "#{mycntrl}", '--port', port, '--device', 0, '--type', 'hdd', '--medium', vdisk_name]
                  port = port + 1
               end
            end
         end

         # Custom post-install script below:
         node.vm.provision "shell" do |s|
            s.inline = <<-SHELL
               echo ':: Fixing ROOT access ...'
               echo root:Password1 | chpasswd
               sed -i -e 's/.*UseDNS.*/UseDNS no  # VAGRANT/' \
                  -e 's/.*PermitRootLogin.*/PermitRootLogin yes  # VAGRANT/' \
                  -e 's/.*PasswordAuthentication.*/PasswordAuthentication yes  # VAGRANT/' \
                  /etc/ssh/sshd_config && systemctl restart sshd

               echo ':: Fixing /etc/hosts ...'
               sed -i -e 's/.*#{host}.*/# \\0  # VAGRANT/' /etc/hosts
               cat << _eof >> /etc/hosts
#{etc_hosts}
_eof

               for script in /vagrant/scripts/*.sh; do
                  if [ -x "$script" ]; then
                     echo ":: Running $script ..." >&2
                     $script
                  fi
               done

               ln -s /opt/pwx/bin/pxctl /usr/local/bin/
            SHELL
            s.env = {
               "K8S_MASTER_IP" => "#{k8s_master_ip}",
               "K8S_TOKEN" => "#{k8s_token}",
               "K8S_CIDR" => "#{k8s_cidr}",
               "MYVMIF" => "#{myvmif}",
               "MYSTORAGE" => "#{mystorage}",
               "SALT_MASTER" => "70.0.0.65",
               "CA_FILE" => "/vagrant/scripts/PWX_ca.crt",
            }
         end
      end
   end
end

