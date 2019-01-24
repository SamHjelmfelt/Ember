# Ember
Ember provides a solution for running Ambari and Cloudera Manager clusters in Docker (HDP, CDH, and HDF). It was designed to streamline training, testing, and development by enabling multi-node **dev/test** clusters to be installed on a single machine with minimal resource requirements. 

## Update January 24, 2019
1. Rebranding to Ember
2. Cloudera Manager and CDH Support
3. Improved port mapping
4. Updated to latest Ambari and HDP versions


## Pre-built Images
Pre-built versions of the single node samples have been loaded into docker hub. They can be configured with their respective ini files and launched with the following commands: 
```
./ember.sh createFromPrebuiltSample samples/yarnquickstart/yarnquickstart-sample.ini
```
Docker images are composed of layers that can be shared by other images. This allows for a great reduction in the total size of images on disk and over the network. Ember's pre-built images are composed as much as possible to take advantage of this feature. 

## Prerequisites
* 8GB RAM and 30GB disk is recommended for the threeNode sample configuration. 4GB RAM or less is viable for smaller clusters.

* Docker 17+
    ```
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce
    ```

* (Optional) Configure for External Network Access to Nodes    
  1. Add multiple IPs to Host OS (N+1 for N nodes)  
    * Use the interface from VMWare, VirtualBox, or the cloud provider to add extra network adaptors to the VM
    * For example, the threeNode-sample configuration can use 4 IPs: 1 for host, 3 for the cluster.  
  2. Limit SSH on host VM to listen on a Single IP. By default, SSH listens on 0.0.0.0
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
An .ini file is required to define hostnames and a cluster name. An external IP list can be defined to allow external access to the containers. 

HDP/HDF and CDH can be installed manually or through Ambari Blueprints/CM templates. Example blueprint and template files are provided in the samples folder.

### INI Fields:
| | |
|----|----|
|**All Clusters:**| |
| clusterName | Required |
| managerServerHostName | Required |
| hostNames | Required |
| ports | Optional. Comma separated list of ports to bind. Additionally, the format "hostPort:containerPort" can be used to map a container port to a different port on the host) (Default: all HDP and HDF ports) |
| externalIPs | Optional. Only necessary for access from outside the host machine |
| managerVersion | Required |
| clusterVersion | Required to use cluster install script. For Ambari, HDP build number must be specified. It can be found in the HDP repo path. |
|**Ambari Clusters:** | |
| Ambari=true | Required to use Ambari |
| mPacks | Optional. Comma separated list of mPack URLs to install |
| blueprintName | Required to use cluster install script |
| blueprintFile | Required to use cluster install script |
| blueprintHostMappingFile | Required to use cluster install script |
| buildRepo=true | Optional. Creates a container with a local yum repo for HDP |
| **Cloudera Manager Clusters:** | |
| templateFile | Required to use cluster install script |

Note: mPacks and local repos are not supported for Cloudera-Manager-based clusters


## Docker images
Ember has five docker images: one for HDP repos, two for Ambari, and two for Cloudera Manager. Ambari, CM, CDH, and HDP versions are configurable, and multiple versions can exist on the same host. Ambari mPacks (such as for HDF or HDPSearch) are also configurable.

1. **HDP Repo Image (Optional)** This container installs and runs a local HDP repo. Creating this image will take time initially, but will greatly speed up all future HDP installs.
2. **Ambari Server Image:** This container installs and runs the Ambari Server and Ambari Agent. If mPacks are defined, they will be installed into Ambari Server as well.
3. **Ambari Agent Image:** This container runs an Ambari Agent process. For multi-node cluster deployments, all nodes except the node designated as the Ambari Server node will be based on this image.
4. **Cloudera Manager Server Image:** This container installs and runs the CM Server and CM Agent.
5. **Cloudera Manager Agent Image:** This container runs the CM Agent process. For multi-node cluster deployments, all nodes except the node designated as the CM Server node will be based on this image.

Both the pullImages and buildImages are configured using a cluster ini file. This is where Ambari vs. CM and versions are set.
```
./ember.sh pullImages samples/yarnquickstart/yarnquickstart-sample.ini
or
./ember.sh buildImages samples/yarnquickstart/yarnquickstart-sample.ini
```

## Creating a Cluster
A blank Ambari/Cloudera Manager cluster is the starting point:
```
./ember.sh createCluster samples/yarnquickstart/yarnquickstart-sample.ini
```

## Installing Services
Once the Ambari/Cloudera Manager cluster is created, the management UI or blueprints/templates can be used to install cluster services. 

To use blueprints or templates, add the appropriate fields to the ini file and run the installCluster command. Sample blueprints and templates are provided in the samples directory.

```
./ember.sh installCluster samples/yarnquickstart/yarnquickstart-sample.ini
```

## Supporting Files/Scripts
This project includes several additional utility methods: 

1. **Install Status:** Monitor the status of a cluster install (the management UI can also be used). Not supported for CM-based clusters.

    ```
    ./ember.sh installStatus samples/yarnquickstart/yarnquickstart-sample.ini
    ```

2. **Stats:** Monitor the resource utilization of a cluster based on the built-in `docker status` command
        
    ```
    ./ember.sh stats samples/yarnquickstart/yarnquickstart-sample.ini
    ```

3. **Create Node:** Create a new node. Note: does not install services or add to Ambari/Cloudera Manager
        
    ```
    ./ember.sh createNode samples/yarnquickstart/yarnquickstart-sample.ini worker1 172.16.96.140
    ```

4. **Export Blueprint:** Export blueprint from Ambari or template from Cloudera Manager

    ```
    ./ember.sh exportBlueprint samples/yarnquickstart/yarnquickstart-sample.ini > blueprint.json
    ```
    
5. **Stop Cluster:** Stop cluster preserving configuration

    ```
    ./ember.sh stopCluster samples/yarnquickstart/yarnquickstart-sample.ini
    ```
    
6. **Start Cluster:** Restarts cluster (including all services) that was previously stopped

    ```
    ./ember.sh startCluster samples/yarnquickstart/yarnquickstart-sample.ini
    ```
    
7. **Remove Cluster:** Completely remove all nodes from the cluster. Not reversible!

    ```
    ./ember.sh removeCluster samples/yarnquickstart/yarnquickstart-sample.ini
    ```

## Notes
1. A local repository will accelerate installs (only supported for Ambari-based clusters)
2. When external IPs are not in use, the nodes can not be access via SSH. Instead use docker exec:
   ```
   docker exec -it resourcemanager.yarnquickstart bash
   ```
3. Ambari and Cloudera Manager can be stopped when not in use to save on memory
   ```
   docker exec -it resourcemanager.yarnquickstart bash -c "ambari-server stop; ambari-agent stop"
   docker exec -it resourcemanager.yarnquickstart bash -c "ambari-server start; ambari-agent start"
   
   
   docker exec -it node1.essentials bash -c "service cloudera-scm-server stop; service cloudera-scm-agent stop"
   docker exec -it node1.essentials bash -c "service cloudera-scm-server start; service cloudera-scm-agent start"
   ```
4. Multiple clusters can reside on the same machine as long as the cluster names (and external IPs) are unique. The docker container names have ".{clusterName}" appended.
5. The stop and start commands can be used to maintain multiple clusters on the same machine. Stopped clusters only require disk space.
6. The containers are configured to autostart if they were not manually stopped. Run this command on the host machine to autostart the docker service.
   ```
   systemctl enable docker
   ```
7. Installing Oozie on HDP requires following these steps: https://docs.hortonworks.com/HDPDocuments/Ambari-2.7.3.0/managing-and-monitoring-ambari/content/amb_enable_the_oozie_ui.html
 
## Potential Enhancements
1. Additional samples
    - HA
2. Local repo for Cloudera Manager
3. Add Kerberos script
4. Add local repo for Ambari mPack services
5. Optimize blueprints/templates to reduce footprint and improve performance
