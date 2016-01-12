Ambari2.2
===========
Dockerfiles and scripts for setting up an HDP cluster using Ambari 2.2. This setup uses Ambari Blueprints to automatically bootstrap the installation of an HDP 2.3.0.0 cluster. THIS VERSION OF THE DOCKER ENVIRONMENTS DOES NOT USE A LOCAL REPO - JUST FYI.

Note: the scripts provided are currently designed to be executed on a Hortonworks Base classroom VM. Some modifications to host name and other details will be needed to run in a different environment.

Preparing Docker Images
---------------------

3 Docker images need to be built:

1. Parent image: this container does basic preparation needed on all HDP cluster nodes - enabling password-less ssh, installing basic utility packages, setting environment variables, etc.

```
cd ambari_2.2_node
docker build -t hwxu/ambari_2.2_node .
```

2. Ambari Server image: this container installs and runs the Ambari Server process, along with an Ambari Agent process. Blueprint installs are initiated from this container. This container also builds a local yum repository mirror for the HDP 2.2.4.2 packages (base CentOS packages are not currently mirrored), so creating this image will take some time. The local mirror is entirely optional and can be disabled/removed if desired.

```
cd ../ambari_2.2_server_node
docker build -t hwxu/ambari_2.2_server_node .
```

3. Ambari Agent image: this container runs an Ambari Agent process, but no Ambari Server. For multi-node cluster deployments, all nodes except the node designated as the Ambari Server node will be based on this image.
 
```
cd ../ambari_2.2_agent_node
docker build -t hwxu/ambari_2.2_agent_node .
```

Launching a Cluster
------------------------

Once the Docker images are built, you are ready to launch an HDP cluster based on one of the provided Ambari blueprints (found in `dockerfiles/ambari_2.2_server_node/blueprints`). You can launch a single node or multi-node cluster. Note that HDP 2.3 has many components, and running a large multi-node cluster is difficult on a single VM. No more than 3 nodes are recommended on a single local VM.

```
/scripts/ambari_single_node.sh [blueprint-base-name]
```

The blueprint name parameter is optional, and defaults to `singlenode`, which installs all HDP 2.3 components on a single cluster node. An alterative blueprint for this script would be `singlenode-min`, which only installs Core Hadoop, Pig, and Hive on a single cluster node.

```
/scripts/ambari_multi_node.sh [number of workers] [blueprint-base-name]
```

Both parameters are optional. Number of workers defaults to 4 (in addition to 3 master nodes always started with this configuration). Default blueprint name is `multinode`, which installs all HDP 2.3 components across multiple nodes.

For multi-node clusters, a recommended lighter-weight blueprint option is 3node:

```
/scripts/ambari_multi_node.sh 0 3node
```

Supporting Files/Scripts
------------------------

This project uses several simple shell scripts to automate much of the bootstrapping and cluster install process. A brief explanation of each follows:

- `/dockerfiles/ambari_2.2_node`:

1. `/scripts/startup.sh`: entry point bootstrap script for all Docker containers. This generic script simply calls an ordered sequence of other shell scripts stored in `start-scripts`

2. `/start-scripts/00-start-node.sh`: first bootstrap script invoked for any container in this project - starts ssh, ntp, disables THP, configures /etc/hosts, and sets up appropriate links for Java

3. `/start-scripts/99-bash.sh`: last bootstrap script invoked for any container in this project - simply runs a bash shell to prevent the container from terminating immediately

- `/dockerfiles/ambari_2.2_server_node`:

1. `/blueprints`: contains a predefined set of Ambari blueprints which are automatically made available in the Ambari Server container. Any of these blueprints can be referenced in the cluster start scripts referenced above. For each blueprint, there is also a host mapping file that maps the logical components locations defined in the blueprint file with the actual nodes where they will be installed. There are 2 single node and 2 multi node blueprints defined. More blueprints can be created and added to this folder.

2. `/repos`: contains custom local repo locations to use during an Ambari blueprints install. If you decide not to use the local mirrored repo, these will not be needed.

3. `/scripts`: contains shell scripts which can be launched within the Ambari Server container to start a blueprints install, check the status of an existing install, or export a blueprint from a currently running cluster. Note: by default, `install_cluster.sh` will be automatically executed with the specified blueprint when the Ambari Server container is bootstrapped.

4. `/start-scripts/05-start-ambari.sh`: bootstrap script that only executes in the Ambari Server container. Makes a few config changes to the Ambari Server, starts Apache for the local repo mirror, and starts Ambari Server and Agent. 

5. `/start-scripts/10-prepare-blueprints.sh`: bootstrap script that waits for Ambari Server to start, then initiates the blueprints based cluster install using the blueprint provided in the cluster start script described above

- `/dockerfiles/ambari_2.2_agent_node`:

1. `/start-scripts/05-start-ambari.sh`: bootstrap script that starts the Ambari Agent process
