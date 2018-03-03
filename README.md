# Welcome

In this project you will learn how to effectively bootstrap a kubernetes cluster. The code is only based on shell script, which makes it easy to read and understand.

### Prerequisites

You need to have vagrant and VirtualBox installed. I am testing with:
```
vagrant version 2.0.1

VirtualBox version 5.2.0
```
Please, if you have bugs with other version feel free to open issues.

### Bootstrap your cluster

To bootstrap the cluster, you just need to clone the repo:

```
git clone git@github.com:abelgana/s-k8s.git
```

Once you have the repo, just cd into s-k8s and run:

```
vagrant up
```

Vagrant will not only start the VM, it will also provision them. Two types of provisioners are used. Docker provisioner is used to pull the images required to bootstrap the clusters' components, and the shell provisioner is used to start the cluster itself.
Once the provisionning is over, you can ssh into the master node:
```
vagrant ssh master-01
```
To get all the running nodes:

```
kubectl get nodes
```

To see all the running pods:

```
kubectl get pods --all-namespaces
```
