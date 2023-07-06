#!/bin/bash

asd &&
sleep 3 &&
nohup /opt/gremlin-server/bin/gremlin-server.sh /opt/aerospike-firefly/conf/firefly-gremlin-server.yaml &
exec "$@"