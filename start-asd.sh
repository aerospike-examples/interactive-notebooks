#!/bin/bash

asd &&
sleep 3 &&
python3 -m graph_notebook.ipython_profile.configure_ipython_profile &&
nohup /opt/gremlin-server/bin/gremlin-server.sh start & disown

exec "$@"