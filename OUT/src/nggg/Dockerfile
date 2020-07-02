# install debian version
FROM debian:buster

# specifie if you want the author
MAINTAINER youcef <yarab@student.42.fr>

# install all the composant we need, nginx, mariadb, php different version
RUN apt update && \
	apt install -y nginx \
				   php-fpm \
	               mariadb-server \
				   php-mysql \
				   php-mbstring \
				   curl

# define our two directories, wordpress and phpmyadmin and copy our folders
RUN mkdir /var/www/wordpress /var/www/phpmyadmin
COPY srcs/wordpress /var/www/wordpress
COPY srcs/phpmyadmin /var/www/phpmyadmin

# edit the default file of nginx with the one we created 
# that links wordpress and phpmyadmin to nginx
COPY srcs/nginx_conf /etc/nginx/sites-available/
RUN rm /etc/nginx/sites-enabled/default && \
	ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# create rot folder
COPY srcs/scripts /root/scripts

RUN service mysql start && \
	mysql -u root < /root/scripts/wp.sql && \
	sh /root/scripts/certificates.sh

# define the entry port
EXPOSE 80 4000

CMD ["/root/scripts/start.sh"]
