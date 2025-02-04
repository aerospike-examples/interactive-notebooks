#!/bin/bash

asd &&
sleep 3 &&
source /usr/local/bin/set_roster.sh &&
sleep 3 &&
asrestore --input-file /backup/sandbox.asb &&
exec "$@"