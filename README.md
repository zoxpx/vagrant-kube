# Kubernetes via Vagrant

This repository contains a self-contained [Vagrant](https://en.wikipedia.org/wiki/Vagrant_(software))-setup for Kubernetes VM cluster with [Portworx](https://portworx.com) storage.

## Prerequisites

Make sure you have the following installed on your Linux host system:

* Virtualbox (install native package from distro, or download from [www.virtualbox.org](https://www.virtualbox.org/))
* Vagrant (download from [www.vagrantup.com](https://www.vagrantup.com/))

## Installation and Usage

To create and start the cluster, simply run the `vagrant up` command where your "Vagrantfile" is.

```bash
# Start Vagrant VM's
vagrant up

# Once VM's are up, log into the k8s master, and check the kubernetes nodes
vagrant ssh kb-master
kubectl get nodes -o wide

# One can also use the IPs to connect directly
ssh root@192.168.56.70
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
kubectl get pods -o wide               # repeat a few times until POD is ready

# Failover TEST:
## 1) Kill MySQL POD via `kubectl delete pod <mysql-pod-id>`,
## 2) run `kubectl get pods -o wide` to validate DB failed over to a new node,
## 3) run `kubectl exec -it <mysql-pod-id> -- /usr/bin/mysql -uroot -ppasswd` to validate DB data
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
# Install latest Docker instead of native/distro package:
chmod a+x scripts/10a-install_docker_latest.sh
chmod a-x scripts/10b-install_docker_native.sh
```

### Customize Networking

The current Vagrantifle is set up to use [host-only network](https://www.virtualbox.org/manual/ch07.html#network_hostonly),
which means the _second_ network interface is set to a "private" network between your host-system and the VM guests.

> **NOTE**: Note also that the VMs will have the _first_ network interface set to NAT-network IP 10.0.2.15, but this is a limitation of "vagrant" utility.

If you want to change the setup to use the IPs from your company's network instead of "host-only" Virtualbox network, do the following:

1. Ensure that `vm_nodes` variable uses a block of "free" IP addresses (e.g. IP addresses not normally in use),
2. Change the following line in the `Vagrantfile`:

```ruby
         unless ip.nil?
            node.vm.network "private_network", ip: "#{ip}", :netmask => "255.255.255.0"
         else
            node.vm.network "public_network", bridge: "eth0", use_dhcp_assigned_default_route: true
         end
```

... into:

```ruby
         node.vm.network "public_network", ip: "#{ip}", :netmask => "255.255.255.0"
```


### ADVANCED: Add your own VM-image

To introduce your own image, or to use a different image for your guest VMs (see [app.vagrantup.com/boxes](https://app.vagrantup.com/boxes/search?provider=virtualbox) for more VM images), edit the `vm_conf` variable, and add a line with the following parameters:

1. name of the harshicorp.com virtualbox image (e.g. `ubuntu/xenial64`)
2. name of the _second_ network interface (e.g. `eth1`)
3. name of the configured storage controller (e.g. `SATA Controller`)
4. starting index of the storage-port (e.g. port#1 == /dev/sdb)
5. disk device and size in Mb (e.g. `{ "sdb" => 15*1024, "sdc" => 20*1024 }` adds 15Gb /dev/sdb and 20Gb /dev/sdc)

```ruby
vm_conf = {
   'ubuntu16' => [ 'ubuntu/xenial64', 'enp0s8', 'SCSI', 2, { "sdc" => 15*1024, "sdd" => 20*1024 } ],
   'centos7'  => [ 'centos/7', 'eth1', 'IDE', 1, { "sdb" => 20*1024 } ],
}
```
