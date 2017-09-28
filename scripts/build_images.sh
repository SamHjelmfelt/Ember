#!/bin/bash

ambariVersion="2.5.2.0"
hdpVersion="2.6.2.0"

repo=true
defaultmPackURLs="http://public-repo-1.hortonworks.com/HDF/centos6/3.x/updates/3.0.1.1/tars/hdf_ambari_mp/hdf-ambari-mpack-3.0.1.1-5.tar.gz"
defaultmPackURLs="$defaultmPackURLs,http://public-repo-1.hortonworks.com/HDP-SOLR/hdp-solr-ambari-mp/solr-service-mpack-2.2.8.tar.gz"

mPackURLs=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    #-r) repo="$2"; shift 2;;

    --noRepo) repo=false; shift 1;;
    --mPack=*) mpURL=${1#*=}; mPackURLs="$mPackURLs,$mpURL"; shift 1;;
    --ambariVersion=*) ambariVersion="${1#*=}"; shift 1;;
    --hdpVersion=*) hdpVersion="${1#*=}"; shift 1;;
    --mPack) echo "$1 requires an argument" >&2; exit 1;;

    -*) echo "unknown option: $1" >&2; exit 1;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

if [ -z "$mPackURLs" ]; then
    mPackURLs=$defaultmPackURLs;
    echo "Using default mPacks";
fi


if [[ $1 = "--noRepo" ]]; then
  echo "Not creating local repo"
else
  docker build \
              --build-arg hdpVersion=$hdpVersion \
              -t dockerdoop/"reponode_${hdpVersion//./-}" \
              repo_node
  docker network create repoNet
  docker run --privileged=true \
              --security-opt seccomp:unconfined \
              --cap-add=SYS_ADMIN \
              -d \
              --dns 8.8.8.8 \
              --name "reponode_${hdpVersion//./-}" \
              -h reponode \
              --net repoNet \
              --restart unless-stopped \
              -i \
              -t dockerdoop/"reponode_${hdpVersion//./-}"  \
              ||
  docker start "reponode_${hdpVersion//./-}"
  docker network connect bridge "reponode_${hdpVersion//./-}"

fi

docker build --build-arg ambariVersion=$ambariVersion -t 'dockerdoop/ambari_agent_node_'$ambariVersion ambari_agent_node

docker build --build-arg ambariVersion=$ambariVersion --build-arg mPacks="$mPackURLs" -t 'dockerdoop/ambari_server_node_'$ambariVersion ambari_server_node
