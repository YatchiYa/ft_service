FROM alpine:latest
MAINTAINER yarab

RUN apk update && apk add --no-cache bash nginx openssh

COPY ./index.html /var/www/localhost/htdocs
COPY ./setup.sh /tmp/

EXPOSE 80 443 22

ENTRYPOINT ["/tmp/setup.sh"]