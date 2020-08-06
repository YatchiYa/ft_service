#!/bin/sh

mkdir -p /etc/ssl/private
mkdir -p /etc/ssl/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=KO/ST=Paris/L=yarab/O=42Paris/CN=ft_services"	-keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/certs/vsftpd.crt

mkdir -p /var/ftp

adduser -D -h /var/ftp admin
echo "admin:admin" | chpasswd

vsftpd /etc/vsftpd/vsftpd.conf