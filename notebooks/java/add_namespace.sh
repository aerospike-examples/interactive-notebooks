#!/usr/bin/sh
cp /etc/aerospike/aerospike.conf ~/notebooks/java/aerospike.conf
sed -i '/paxos-single-replica-limit/d' ~/notebooks/java/aerospike.conf
echo "namespace $1 {\n memory-size 1G \n}" >> ~/notebooks/java/aerospike.conf
pkill asd; asd --config-file ~/notebooks/java/aerospike.conf
