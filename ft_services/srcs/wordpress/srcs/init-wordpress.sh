#! /bin/sh

sleep 5
mysql --host=mysql --user=admin --password=yarab wordpress < /tmp/wordpress.sql > /dev/null 2>&1
until [ $? != 1 ]
do
	sleep 1
	mysql --host=mysql --user=admin --password=yarab wordpress < /tmp/wordpress.sql > /dev/null 2>&1
done
