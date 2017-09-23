#!/bin/bash

for script in `ls -1 /root/start-scripts/`
do
    /root/start-scripts/$script > /tmp/${script}.out 2> /tmp/${script}.err
done
