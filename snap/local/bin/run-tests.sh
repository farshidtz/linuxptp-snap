#!/bin/bash -e

cp -r $SNAP/linuxptp-testsuite /tmp/
PATH=$PATH:$SNAP/usr/local/sbin/

cd /tmp/linuxptp-testsuite
./run
