#!/bin/bash
echo "Vagrant build scenario"

# output with some color and font weight
function drawtext() {
	tput $1
	tput setaf $2
	echo -n $3
	tput sgr0
}

# Make sure we run with root privileges
if [ $UID != 0 ];
	then
# not root, use 
	echo "This script needs root privileges, rerunning it now using !"
	 "${SHELL}" "$0" $*
	exit $?
fi
# get real username
if [ $UID = 0 ] && [ ! -z "$_USER" ];
	then
	USER="$_USER"
else
	USER="$(whoami)"
fi

# <----- START APLICATION ------>
#	WorkSpace
HOME_DIR="tmw_home"
LOG_FILE=/$HOME_DIR/scenario.log
echo APLICATION STARTED --- $( date +"%H-%M-%S_%d-%m-%Y") >> ${LOG_FILE} 
echo echo "$(drawtext bold 2 "[ OK ]")" ---APLICATION STARTED --- $( date +"%H-%M-%S_%d-%m-%Y")
# MySQL
# Create MySQL  Variables
MySQL_ROOT_Pass="1a_ZaraZa@"
MySQL_User="tmw"
MySQL_User_Pass="la_3araZa"

# Create mysql_secure_installation.sql
cd ${HOME_DIR}
# Change the root password for MySQL
#info: https://stackoverflow.com/questions/33510184/change-mysql-root-password-on-centos7
echo MySQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log) > Pass.txt 
echo MySQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | rev | cut -c1-12 | rev) >> Pass.txt 
MySQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | rev | cut -c1-12 | rev) 
mysqladmin --user=root --password="$MySQL_TMP_PASS" password "$MySQL_ROOT_Pass"
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "MySQL")" successfully configurated"

# Write database login & passwd to application config file
# Create DataBase (From Chernov)
echo "Creating databese: tmw and user: tmw"
mysql -u root -p"${MySQL_ROOT_Pass}" -e "CREATE DATABASE tmw DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;"
#Create a new user with same name as new DB
mysql -u root -p"${MySQL_ROOT_Pass}" -e "GRANT ALL ON tmw.* TO '${MySQL_User}'@'localhost' IDENTIFIED BY '${MySQL_User_Pass}';"
mysql -u root -p"${MySQL_ROOT_Pass}" -e "FLUSH PRIVILEGES"
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "MySQL DATABASE")" successfully created"

# GIT section
echo "Git clone application..."
cd /opt
git clone https://github.com/if-078/TaskManagmentWizard-NakedSpring-.git > /dev/null 2>&1
cd TaskManagmentWizard-NakedSpring-/src/test/resources
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "GIT]")" successfully Cloned"
# Import settings from application to MySQL database
echo "Set settings to MySQL tmw DATABASE tables"
mysql -u "${MySQL_User}" -p"${MySQL_User_Pass}" tmw <create_db.sql
mysql -u "${MySQL_User}" -p"${MySQL_User_Pass}" tmw <set_dafault_values.sql
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "MySQL Tables")" successfully installed"

# Script take from Oleksandr Sepelyuk
cd /opt/TaskManagmentWizard-NakedSpring-
MCONF=src/main/resources/mysql_connection.properties
sed -i 's/jdbc.username=root/jdbc.username=tmw/g' $MCONF
sed -i 's/jdbc.password=root/jdbc.password='$MySQL_User_Pass'/g' $MCONF
echo "Setup complete!"

# Add PORT 8585 to INPUT RULES
sudo iptables -I INPUT 1 -p tcp -m tcp --dport 8585 -j ACCEPT

# RESTARRT iptables 
sudo sed -i 's/IPTABLES_SAVE_ON_STOP=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config
sudo sed -i 's/IPTABLES_SAVE_ON_RESTART=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config

# Run application
echo "Run WAR application"
mvn tomcat7:run-war
