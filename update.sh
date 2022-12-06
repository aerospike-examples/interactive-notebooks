#!/bin/bash
set -e

if [ -z "$1" ]; then

   serverVer="$(curl -sSL 'https://download.aerospike.com/artifacts/aerospike-server-enterprise/' | grep -E '<a href="[0-9.-]+[-]*.*/"' | sed -r 's!.*<a href="([0-9.-]+[-]*.*)/".*!\1!' | sort -V | tail -1)"

else 
   serverVer=$1
fi

toolsVer="$(curl -sSL 'https://download.aerospike.com/artifacts/aerospike-tools/' | grep -E '<a href="[0-9.-]+[-]*.*/"' | sed -r 's!.*<a href="([0-9.-]+[-]*.*)/".*!\1!' | sort -V | tail -1)"

sha256="$(curl -sSL "https://download.aerospike.com/artifacts/aerospike-server-enterprise/${serverVer}/aerospike-server-enterprise_${serverVer}_tools-${toolsVer}_ubuntu20.04_x86_64.tgz.sha256" | cut -d' ' -f1)"

set -x
sed -ir 's/^\(ENV AEROSPIKE_VERSION\) .*/\1 '"$serverVer"'/; s/^\(ENV AEROSPIKE_SHA256\) .*/\1 '"$sha256"'/; s/^\(ARG AEROSPIKE_TOOLS_VERSION\).*/\1='"$toolsVer"'/'  Dockerfile
