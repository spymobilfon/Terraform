#!/bin/bash

while [ ! -f /opt/init-finished ]; do
    echo "Waiting for init finished..."
    sleep 60
done
