FROM alpine:latest

# update && install nginx && bash && openssl && folder for nginx pid
RUN apk update && apk add nginx \
&& apk add --no-cache --upgrade bash \
&& apk add openssl && mkdir -p var/run/nginx \
&& apk add openssl openssh \
&& rm -rf /var/cache/apk/*

# create user for nginx && generate nginx folder && add permissions
RUN adduser -D -g 'www' www \
&& mkdir /www && chown -R www:www /var/lib/nginx \
&& chown -R www:www /www

# SSL
RUN mkdir /etc/nginx/ssl \
&& openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out /etc/nginx/ssl/www.pem -keyout /etc/nginx/ssl/www.key -subj "/C=FR/ST=Paris/L=Paris/O=42 School/OU=yarab/CN=ft_services"
RUN ssh-keygen -A


# Nginx config
RUN rm /etc/nginx/nginx.conf

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY index.html /www/index.html
COPY index.css /www/index.css
COPY s-l1600.jpg /www/s-l1600.jpg
COPY sshd_config /etc/ssh/sshd_config
COPY setup.sh .

RUN chmod +x setup.sh

EXPOSE 6666 80 443
CMD ./setup.sh
