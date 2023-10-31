#!/bin/bash

asd &&
sleep 3 &&
export CLASSPATH=$(cat /opt/classpath.txt) &&
python3 -m graph_notebook.ipython_profile.configure_ipython_profile &&
nohup /opt/gremlin-server/bin/gremlin-server.sh /opt/aerospike-firefly/conf/firefly-gremlin-server.yaml & disown

exec "$@"