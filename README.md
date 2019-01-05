# Kubernetes via Vagrant

This repository contains a self-contained [Vagrant](https://en.wikipedia.org/wiki/Vagrant_(software))-setup for Kubernetes VM cluster with [Portworx](https://portworx.com) storage.

## Prerequisites

Make sure you have the following installed on your Linux host system:

* Virtualbox (install native package from distro, or download from [www.virtualbox.org](https://www.virtualbox.org/))
* Vagrant (download from [www.vagrantup.com](https://www.vagrantup.com/))

## Installation and Usage

To create and start the cluster, simply run the `vagrant up` command.

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

## Customizations

### Number of nodes, node IPs

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

### VM's Linux OS type

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
