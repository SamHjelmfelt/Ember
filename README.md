# DockerDoop
DockerDoop provides a solution for running HDP on Docker. It was designed to streamline HDP training, administrative testing, and certain development tasks.

This solution is an intermediate step between the HDP Sandbox and multi-machine HDP installations for **dev/test workloads**. With DockerDoop, multi-node HDP clusters can be installed quickly and easily on a single machine with minimal resource requirements. 

8GB RAM and 50GB disk is recommended for the multinode sample configuration. 6GB or less RAM may be viable for smaller clusters.

## Updates September 27, 2017
1. Upgraded to Centos 7
2. Upgraded to OpenJDK 8
3. Created separate HDP repo container
4. Refactored images
5. Made HDP and Ambari versions configurable
6. Added support for Ambari mPacks (Defaults: HDF, HDP Search)

## Install Modes
1. In a local VM
    - Sandboxed, "Cluster in a box"
3. On a shared machine
    - Collaborative clusters

## Prerequisites

* CentOS 7 (Other Linux operating systems should work as well)
* Docker 17 
-https://docs.docker.com/engine/installation/linux/docker-ce/centos/

* Configure for External Network Access to Nodes    
  1. Add multiple IPs to Host OS (N+1 for N nodes)  
    * Use VMWare/VirtualBox/etc. to add network adaptors to the VM
    * For example, the threeNode-sample configuration requires 4 IPs: 1 for host, 3 for the cluster.  
  2. Limit SSH on host VM to a Single IP. By default, SSH listens on 0.0.0.0
     * Edit sshd_config
       ```
       vi /etc/ssh/sshd_config  
       ```  
     * Add the following line with the IP address for the host OS:  
       ```
       ListenAddress <IP Address>  
       ```  
     * Restart sshd  
       ```
       service sshd restart  
       ```      
  3. Enable IPv4 forwarding  
      ```
      sysctl -w net.ipv4.ip_forward=1  
      ```

## Configuration
An .ini file is required to define hostnames and a cluster name. An external IP list can be defined to allow external access to nodes. 

HDP can be installed manually or through Ambari Blueprints. Example blueprint files are provided in the blueprints folder.

#### INI Fields:

* clusterName (required)
* ambariServerHostName (required)
* hostNames (required)
* externalIPs (required for external access to nodes)

* ambariVersion (required) (Default is 2.6.2.0)
* hdpVersion (required to use blueprint script) (Default is 2.6.5.0-292) (Note: build number must be specified)
* blueprintName (required to use blueprint script)
* blueprintFile (required to use blueprint script)
* blueprintHostMappingFile (required to use blueprint script)  


## Preparing Docker Images
Three docker images are included. Note that the HDP and Ambari versions are configurable, and multiple versions can exist on the same host. Ambari mPacks (such as for HDF or HDPSearch) are also configurable.

1. **HDP Repo Image (Optional)** This container installs and runs a local HDP repo in its own docker container. Creating this image will take some time.
1. **Ambari Server Image:** This container installs and runs the Ambari Server and Ambari Agent. If mPacks are defined, they will be installed into Ambari Server as well.
2. **Ambari Agent Image:** This container runs an Ambari Agent process, but no Ambari Server. For multi-node cluster deployments, all nodes except the node designated as the Ambari Server node will be based on this image.

   ```
   ./scripts/build_images.sh [--noRepo] [--ambariVersion=2.6.2.0] [--hdpVersion=2.6.5.0-292] [--mPack={bundleURL}]
   ```

## Creating a Cluster
Once the Docker images are built, the cluster nodes can be created and Ambari can be started.

```
./scripts/createCluster.sh threeNode-sample.ini
```

## Installing HDP
Once a cluster is set up, the Ambari UI or blueprints can be used to install the cluster. 

To use blueprints, add the blueprint fields to the ini file to use the included script. Sample blueprints and host mapping files are provided in the blueprints directory.

```
/scripts/installCluster.sh threeNode-sample.ini
```

## Supporting Files/Scripts
This project includes several additional scripts: 

1. **Install Status:** Monitor the status of a blueprint install. Note: the Ambari UI can also be used.

      ```
      ./scripts/installStatus.sh threeNode-sample.ini
      ```

2. **Stats:** Monitor the resource utilization of a cluster or all clusters on a machine using the built in `docker status` command
        
    ```
    ./scripts/stats.sh threeNode-sample.ini 
    ```
    ```
    ./scripts/stats.sh
    ```

3. **Create Node:** Create a new node. Note: does not install services or add to Ambari
        
    ```
    ./scripts/createNode.sh  HWorker4 HMaster 172.16.96.140 HCluster
   ```

4. **Export Blueprint:** Export blueprint from Ambari

    ```
    ./scripts/exportBlueprint.sh threeNode-sample.ini
    ```

5. **Start/Stop Cluster:** Start and stop the docker containers running the cluster. Similar to powering on/off machines.

    ```
    ./scripts/stopCluster.sh threeNode-sample.ini
    ```  
    ```
    ./scripts/startCluster.sh threeNode-sample.ini
    ```

6. **Destroy Cluster:** Completely remove all nodes from the cluster. Not reversible!

    ```
    ./scripts/destroyCluster.sh threeNode-sample.ini
    ```

## Notes
1. A local repository to really accelerate install processes.
2. Multiple clusters can reside on the same machine as long as the cluster names (and external IPs) are unique. The docker container names have ".{clusterName}" appended.
3. Use the stop and start functionality to keep multiple cluster versions and/or configurations.
4. The containers are configured to autostart if they were not manually stopped. Run this command to autostart the docker service.
   ```
   chkconfig docker on
   ```
5. Installing Oozie requires following these steps: https://docs.hortonworks.com/HDPDocuments/Ambari-2.7.1.0/managing-and-monitoring-ambari/content/amb_enable_the_oozie_ui.html
 
## Potential Enhancements
1. Additional sample blueprints
    - HA
    - Standalone use cases (streaming, data science, batch, etc.)
2. Add Kerberos support
3. Add local repo for mPack services
4. Optimize settings to reduce footprint and improve performance