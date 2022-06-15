#!/bin/bash

asd &&
sleep 3 &&
asrestore --input-file /backup/sandbox.asb &&
. /usr/local/bin/start-notebook.sh