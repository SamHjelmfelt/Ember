#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <configuration.ini> "
  exit -1
fi
iniFile=$1

clusterName=$(awk -F "=" '/clusterName/ {print $2}' $iniFile)
blueprint=$(awk -F "=" '/blueprint/ {print $2}' $iniFile)
hostNames=$(awk -F "=" '/hostNames/ {print $2}' $iniFile)
ambariVersion=$(awk -F "=" '/ambariVersion/ {print $2}' $iniFile)
ambariServerHostName=$(awk -F "=" '/ambariServerHostName/ {print $2}' $iniFile).$clusterName

hostNameArr=(${hostNames//,/ })
len=${#hostNameArr[@]}

if grep -q "externalIPs" $iniFile ; then

    externalIPs=$(awk -F "=" '/externalIPs/ {print $2}' $iniFile)
    externalIpsArr=(${externalIPs//,/ })

    if [ ${#hostNameArr[@]} -ne ${#externalIpsArr[@]} ]; then
        echo "The number of host names defined do not match the number of IPs defined!"
        exit 1
    fi

    for i in $(seq 0 $(($len-1)));
    do
      ./scripts/createNode.sh $ambariVersion ${hostNameArr[$i]} $ambariServerHostName $clusterName ${externalIpsArr[$i]}
    done
else
    for i in $(seq 0 $(($len-1)));
    do
      ./scripts/createNode.sh $ambariVersion ${hostNameArr[$i]} $ambariServerHostName $clusterName
    done
fi




#./scripts/createNode.sh node1 namenode hxucluster 172.16.96.140
