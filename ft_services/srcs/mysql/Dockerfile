FROM alpine
RUN apk update
RUN apk add mysql
RUN mkdir -p /run/mysqld
COPY srcs/my.cnf /etc/mysql/
COPY srcs/mysql-init /tmp/
COPY srcs/run.sh /tmp/

EXPOSE 3306

ENTRYPOINT ["sh", "/tmp/run.sh"]
