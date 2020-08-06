#!/bin/sh

mkdir -p /var/run/nginx

ssh-keygen -A
adduser --disabled-password admin
echo "admin:admin" | chpasswd
/usr/sbin/sshd

nginx -g "daemon off;"
