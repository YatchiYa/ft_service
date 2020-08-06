#!/bin/sh

mkdir -p /ftps/yarab
adduser --home=/ftps/yarab -D yarab

echo "yarab:yarab" | chpasswd
echo "yarab" >> etc/vsftpd/vsftpd.userlist

touch /var/log/vsftpd.log

mkdir -p /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem -config etc/ssl/private/openssl.conf
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
