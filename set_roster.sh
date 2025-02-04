#! /bin/bash

NAMESPACE="sandbox"
FILE="/tmp/roster"
asinfo -v roster:namespace=$NAMESPACE > $FILE
observed_nodes=`cat $FILE | grep -o observed_nodes.* | cut -d'=' -f2`
echo $observed_nodes
echo "Setting roster nodes to be the observed nodes"
command="'roster-set:namespace=$NAMESPACE;nodes=$observed_nodes'"
asadm --enable -e "asinfo -v $command"
if [ "$?" -eq 0 ]
then
    echo "Roster set, reclustering..."
    asadm --enable -e "asinfo -v recluster"
fi
asinfo -l -v roster
