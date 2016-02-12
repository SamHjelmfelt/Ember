This fork is intended to generalize the solution for dev/test use cases.

Ambari2.2
===========
Dockerfiles and scripts for setting up an HDP cluster using Ambari 2.2. This setup uses Ambari Blueprints to automatically bootstrap the installation of an HDP 2.3.0.0 cluster. 


Prerequisites
---------------------
Docker 1.9+
One external IP configured for each node and the base OS.

Preparing Docker Images
---------------------

3 Docker images need to be built:

1. Parent image: this container does basic preparation needed on all HDP cluster nodes - enabling password-less ssh, installing basic utility packages, setting environment variables, etc.
2. Ambari Server image: this container installs and runs the Ambari Server process, along with an Ambari Agent process. Blueprint installs are initiated from this container. This container also builds a local yum repository mirror for the HDP 2.2.4.2 packages (base CentOS packages are not currently mirrored), so creating this image will take some time. The local mirror is entirely optional and can be disabled/removed if desired.
3. Ambari Agent image: this container runs an Ambari Agent process, but no Ambari Server. For multi-node cluster deployments, all nodes except the node designated as the Ambari Server node will be based on this image.
 
```
./scripts/build_images.sh
```

Launching a Cluster
------------------------
Once the Docker images are built, you are ready to create a cluster using. A ini file is required to define hostnames, external IPs, and a cluster name. Multinode and singlenode examples are provided.

```
./scripts/createCluster.sh multinode-sample.ini
```

Launching a Cluster
------------------------

Once a cluster is set up, The Ambari UI can be used to install the cluster. Each machine has Ambari agent running.

Blueprints can also be used to completely automate the install. Add a blueprint field to the ini file to use the included script. Two sample blueprints and host mapping files are provided in the blueprints directory.

```
/scripts/installCluster.sh multinode-sample.ini
```

Supporting Files/Scripts
------------------------

This project includes several additional scripts: 


1. `/scripts/installStatus.sh`: entry point bootstrap script for all Docker containers. This generic script simply calls an ordered sequence of other shell scripts stored in `start-scripts`

2. `/start-scripts/00-start-node.sh`: first bootstrap script invoked for any container in this project - starts ssh, ntp, disables THP, configures /etc/hosts, and sets up appropriate links for Java

3. `/start-scripts/99-bash.sh`: last bootstrap script invoked for any container in this project - simply runs a bash shell to prevent the container from terminating immediately

