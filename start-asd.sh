#!/bin/bash

asd &&
sleep 3 &&
gremlin-server.sh /opt/aerospike-firefly/conf/firefly-gremlin-server.yaml &

exec "$@"