ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
/usr/sbin/sshd
nginx -g 'daemon off;'
