#!/bin/sh
while :; do
    /etc/kafka-connect/scripts/restart-failed-connector-tasks.sh >> /var/log/connect_monitor.log 2>&1
    sleep 180
done
