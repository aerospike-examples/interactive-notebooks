#!/bin/bash

. /usr/local/bin/start-notebook.sh &&
asd &&
sleep 3 &&
asrestore --input-file /backup/sandbox.asb
