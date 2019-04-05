# Kubernetes via Vagrant

This repository contains a self-contained [Vagrant](https://en.wikipedia.org/wiki/Vagrant_(software))-setup for Kubernetes VM cluster with [Portworx](https://portworx.com) storage.

## Prerequisites

Make sure you have the following prerequisites satisfied before starting your K8s cluster:

* Host running 64bit Linux system, with at least 16 GB RAM
* Virtualbox hypervisor package installed (install distribution's package, or download from [www.virtualbox.org](https://www.virtualbox.org/))
* Vagrant package installed (download from [www.vagrantup.com](https://www.vagrantup.com/))
* Git package installed (in case you are getting these sources directly from Github)

## Installation and Usage

To create and start the cluster, simply run the `vagrant up` command where your "Vagrantfile" is.

```bash
# Start Vagrant VM's
vagrant up

# Once VM's are up, log into the k8s master, and check the kubernetes nodes
vagrant ssh kb-master
kubectl get nodes -o wide

# One can also use the IPs to connect directly from the host
ssh root@192.168.56.80
```

> **NOTE**: If not already present, the VM-images will be downloaded automatically from the Internet by the `vagrant up` command.

### Using Portworx

All the kubernetes nodes (except master) will already have Portworx preconfigured and running on your cluster.

To start a `mysql` database backed by the Portworx persistent volume, apply the 
[vol.yaml](yamls/myql/vol.yaml) and [app.yaml](yamls/myql/app.yaml) on your k8s "master" node:

```bash
# Create portworx volume
kubectl apply -f /vagrant/yamls/myql/vol.yaml

# Start MySQL that uses Portworx storage
kubectl apply -f /vagrant/yamls/myql/app.yaml
kubectl get pods -o wide               # repeat a few times until MySQL POD is ready

# Example: MySQL failover TEST:
# 1) Kill MySQL POD via `kubectl delete pod <mysql-pod-id>`,
# 2) run `kubectl get pods -o wide` to validate DB failed over to a new node,
# 3) run `kubectl exec -it <mysql-pod-id> -- /usr/bin/mysql -uroot -ppasswd` to validate DB data
```

* more information at [docs.portworx.com](https://docs.portworx.com/portworx-install-with-kubernetes/storage-operations/)

## Customizations

### Change number of nodes, or node IPs

Open up [Vagrantfile](Vagrantfile) in your favorite editor.

Edit the `vm_nodes` variable at the top, and specify the nodes and their IPs.  The first node will always be the Kubernetes master.

```ruby
vm_nodes = {            # EDIT to specify VM node names, and their private IP (vboxnet#)
   'kb-master' => "192.168.56.70",
   'kb-node1' => "192.168.56.71",
   'kb-node2' => "192.168.56.72",
   'kb-node3' => "192.168.56.73",
}
```

### Change guest VM's Linux OS

In the same [Vagrantfile](Vagrantfile) find the `ostype` variable, and change it to specify which Linux OS will be used as guest VMs:

```ruby
ostype = 'ubuntu16'     # also 'centos7' or 'bento16'
```

### Customize installation scripts

Check the content of the [scripts](scripts) directory, and change exec-permissions on the install scripts to customize the installation:

```bash
# Example1: Install latest Docker instead of native/distro package:
chmod a+x scripts/10a-install_docker_latest.sh
chmod a-x scripts/10b-install_docker_native.sh

# Example2: Install Kubernetes 1.13 instead of latest:
chmod a+x scripts/30b-install_kubernetes-v1.13.sh
chmod a-x scripts/30a-install_kubernetes_latest.sh
```

### Customize Networking

The current Vagrantifle is set up to use [host-only network](https://www.virtualbox.org/manual/ch07.html#network_hostonly),
which means the _second_ network interface is set to a "private" network between your host-system and the VM guests.

> **NOTE**: the VMs will have the _first_ network interface set to Virtualbox'es NAT-network IP 10.0.2.15.  Unfortunately, this is a limitation of "vagrant" utility and it cannot be changed.

If you want to change the setup to use the IPs from your company's network instead of "host-only" Virtualbox network, do the following:

1. Ensure that `vm_nodes` variable uses a block of "free" IP addresses (e.g. IP addresses not currently in use),
2. Remove the following lines in the `Vagrantfile`:

```ruby
         unless ip.nil?
            node.vm.network "private_network", ip: "#{ip}", :netmask => "255.255.255.0"
         else
            node.vm.network "public_network", bridge: "eth0", use_dhcp_assigned_default_route: true
         end
```

... and replace with:

```ruby
         node.vm.network "public_network", ip: "#{ip}", :netmask => "255.255.255.0"
```


### ADVANCED: Add your own VM-image

To introduce your own image, or to use a different image for your guest VMs (see [app.vagrantup.com/boxes](https://app.vagrantup.com/boxes/search?provider=virtualbox) for more VM images), edit the `vm_conf` variable, and add a line with the following parameters:

1. a unique label for your VM image (will be used as a hashmap-key, e.g. `ubuntu16`)
2. name of the [app.vagrantup.com image](https://app.vagrantup.com/boxes/search?provider=virtualbox) (e.g. `ubuntu/xenial64`)
3. name of the VM's _second_ network interface (e.g. `eth1`)
4. name of the VM's storage controller (e.g. `SATA Controller`)
5. starting index of the VM's storage-port (e.g. port#1 == /dev/sdb)
6. list of disk devices and sizes in MB
   - e.g. `{ "sdb" => 15*1024, "sdc" => 20*1024 }` adds 15GB /dev/sdb and 20GB /dev/sdc

```ruby
vm_conf = {
   'ubuntu16' => [ 'ubuntu/xenial64', 'enp0s8', 'SCSI', 2, { "sdc" => 15*1024, "sdd" => 20*1024 } ],
   'centos7'  => [ 'centos/7', 'eth1', 'IDE', 1, { "sdb" => 20*1024 } ],
}
```
