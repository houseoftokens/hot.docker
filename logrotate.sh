#!/bin/bash

mkdir -p /hot/data/logs

while true; do
    logrotate /hot/conf/logrotate.conf
    sleep 3600; # run each hour
done;
