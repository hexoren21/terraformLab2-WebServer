#!/bin/bash
echo "witaj, swiecie" > index.html
server_port = ${server_port}
nohup busybox httpd -f -p "$server_port" &

