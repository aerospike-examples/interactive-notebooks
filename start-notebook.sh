#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e
asd &&
nohup /opt/gremlin-server/bin/gremlin-server.sh /opt/aerospike-firefly/conf/firefly-gremlin-server.yaml &

# The Jupyter command to launch
# JupyterLab by default
DOCKER_STACKS_JUPYTER_CMD="${DOCKER_STACKS_JUPYTER_CMD:=lab}"

if [[ -n "${JUPYTERHUB_API_TOKEN}" ]]; then
    echo "WARNING: using start-singleuser.sh instead of start-notebook.sh to start a server associated with JupyterHub."
    exec /usr/local/bin/start-singleuser.sh "$@"
fi

wrapper=""
if [[ "${RESTARTABLE}" == "yes" ]]; then
    wrapper="run-one-constantly"
fi

# shellcheck disable=SC1091,SC2086
exec jupyter ${DOCKER_STACKS_JUPYTER_CMD} ${NOTEBOOK_ARGS} "$@"