# DockerDoop
DockerDoop provides a solution for running HDP on Docker. It was designed to streamline HDP training, administrative testing, and certain development tasks.

This solution is an intermediate step between the HDP Sandbox and multi-machine HDP installations for **dev/test workloads**. With DockerDoop, multi-node HDP clusters can be installed quickly and easily on a single machine with minimal resource requirements. 

8GB RAM and 50GB disk is recommended for the multinode sample configuration. 6GB or less RAM may be viable for smaller clusters.


## Install Modes
1. In a local VM
    - Sandboxed, "Cluster in a box"
3. On a shared machine
    - Collaborative clusters

## Prerequisites

* Docker 1.9+  
-https://docs.docker.com/engine/installation/linux/centos/
* CentOS 7 (Other Linux operating systems should work as well)

* Configure for External Network Access to Nodes    
  1. Add multiple IPs to Host OS (N+1 for N nodes)  
    * Use VMWare/VirtualBox/etc. to add network adaptors to the VM
    * For example, the threeNode-sample configuration requires 4 IPs: 1 for host, 3 for the cluster.  
  2. Limit SSH to a single IP. By default, SSH listens on 0.0.0.0
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

* Expand Node Disk Size Beyond 10GB Default. Note: this requires a rebuild of the images  
    1. Create Docker configuration file  
       ```
       mkdir /etc/systemd/system/docker.service.d
       ```  
       ```
       vi /etc/systemd/system/docker.service.d/docker.conf
       ```

    2. Add the following content to the file. 20GB is recommended  
       ```
       [Service]  
       ExecStart=  
       ExecStart=/usr/bin/docker daemon --storage-opt dm.basesize=20G
       ```
    3. Reload and restart Docker Daemon  
       ```
       systemctl daemon-reload  
       systemctl restart docker
       ```
    

## Configuration
An .ini file is required to define hostnames and a cluster name. An external IP list can be defined to allow external access to nodes. 

HDP can be installed manually or through Ambari Blueprints. Example blueprint files are provided in the blueprints folder.

#### INI Fields:

* clusterName (required)
* ambariServerHostName (required)
* hostNames (required)
* externalIPs (required for external access to nodes)
* blueprintName (required to use blueprint script)
* blueprintFile (required to use blueprint script)
* blueprintHostMappingFile (required to use blueprint script)  


## Preparing Docker Images
3 Docker images need to be built:

1. **Parent Image:** This container does basic preparation needed on all HDP cluster nodes - installing basic utility packages, setting environment variables, etc.
2. **Ambari Server Image:** This container installs and runs the Ambari Server and Ambari Agent. This container also builds a local yum repository mirror for the HDP packages (base CentOS packages are not currently mirrored), so creating this image will take some time.
3. **Ambari Agent Image:** This container runs an Ambari Agent process, but no Ambari Server. For multi-node cluster deployments, all nodes except the node designated as the Ambari Server node will be based on this image.
 
   ```
   ./scripts/build_images.sh
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

3. **Create Node:** Create a new node. Note: does not install services
        
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
1. The Ambari Server node hosts a local repository to accelerate the install process.
2. Multiple clusters can reside on the same machine as long as the cluster names (and external IPs) are unique. The docker container names have ".{clusterName}" appended.
3. Use the stop and start functionality to keep multiple cluster versions and/or configurations.
4. The containers are configured to autostart if they were not manually stopped. Run this command to autostart the docker service.
   ```
   chkconfig docker on
   ```
 
## Potential Enhancements
1. Additional sample blueprints
    - HA
    - Kerberos
    - Standalone use cases (streaming, data science, batch, etc.)
2. Optimize settings to reduce footprint and improve performance