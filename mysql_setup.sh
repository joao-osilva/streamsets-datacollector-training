# get randonly generated password and send to container
MYSQL_PWD=$(docker logs mysql 2>&1 | grep GENERATED | awk '{print $5}')
printf "[client]\nuser = root\npassword = $MYSQL_PWD" > my.cnf
docker cp my.cnf mysql:/root
rm my.cnf

# change root's password to 'mysql'
# create a new user(sdc:sdc) and allow him to access the server remotely
docker exec -it mysql mysql --defaults-file=/root/my.cnf --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'mysql';CREATE USER 'sdc'@'%' IDENTIFIED BY 'sdc';GRANT ALL PRIVILEGES ON *.* TO 'sdc'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;"