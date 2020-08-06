FROM alpine:latest

RUN apk add openssl vsftpd --no-cache && apk add lftp
COPY srcs/openssl.conf /etc/ssl/private/
COPY srcs/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY srcs/run.sh /
EXPOSE 20 21 21100-21102
ENTRYPOINT ["/run.sh"]