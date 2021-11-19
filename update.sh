#!/bin/bash
set -e

if [ -z "$1" ]; then

   fullVersion="$(curl -sSL 'https://download.aerospike.com/artifacts/aerospike-server-enterprise/' | grep -E '<a href="[0-9.-]+/"' | sed -r 's!.*<a href="([0-9.-]+)/".*!\1!' | sort -V | tail -1)"

else 
   fullVersion=$1
fi

sha256="$(curl -sSL "https://download.aerospike.com/artifacts/aerospike-server-enterprise/${fullVersion}/aerospike-server-enterprise-${fullVersion}-ubuntu20.04.tgz.sha256" | cut -d' ' -f1)"

set -x
sed -ir 's/^\(ENV AEROSPIKE_VERSION\) .*/\1 '"$fullVersion"'/; s/^\(ENV AEROSPIKE_SHA256\) .*/\1 '"$sha256"'/'  Dockerfile
