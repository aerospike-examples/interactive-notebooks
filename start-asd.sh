#!/bin/bash

asd &&

nohup /opt/gremlin-server/bin/gremlin-server.sh /opt/aerospike-firefly/conf/firefly-gremlin-server.yaml &

exec "$@"