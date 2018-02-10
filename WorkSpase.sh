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

# SetTimeZone
timedatectl set-timezone Europe/Kiev

#<------------------ Create System Environment Variables ------------------>
# JAVA
JHOME_VAR="JAVA_HOME"
JHOME_VALUE="/usr/java/jdk1.8.0_162"
JRE_VAR="JRE_HOME"
JRE_VALUE="/usr/java/jdk1.8.0_162/jre"

# MAVEN
MHOME_VAR="MAVEN_HOME"
MHOME_VALUE="/usr/java/apache-maven-3.5.2"

# FOLDER AND FILE ENVIRONMENTAL
FILEFOLDER="/etc/profile.d"
FILENAME="vars.sh"

# Create new file with environmental variables
touch ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Creating scenario file: $(drawtext bold 2 ${FILENAME})" 

# Writting lines to the file
echo "Writting scenario to the file ${FILENAME}"

echo   "${JHOME_VAR}=${JHOME_VALUE}" > ${FILENAME}
echo   "${JRE_VAR}=${JRE_VALUE}" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${JHOME_VAR}) variable"

echo   "${MHOME_VAR}=${MHOME_VALUE}" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${MHOME_VAR}) variable"

# Add ALL bin folder to the PATH environmental variable
echo "PATH=$PATH:${JHOME_VALUE}/bin:${JRE_VALUE}/bin:${MHOME_VALUE}/bin" >> ${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" ---  "Changing $(drawtext bold 2 "PATH") variable"
# Copying file with variables to the specific folder
mv ${FILENAME} $FILEFOLDER/${FILENAME}
echo "$(drawtext bold 2 "[ OK ]")" --- "Moving file $(drawtext bold 2 ${FILENAME}) to the $(drawtext bold 2 $FILEFOLDER)"

# <----- WorkSpace configurate ------>


# Create Install Environment Variables
#	WorkSpace
HOME_DIR="tmw_home"
LOG_FILE=/$HOME_DIR/scenario.log

cd /
# Create WorkSpace 
mkdir ${HOME_DIR}
cd ${HOME_DIR}
echo "$(drawtext bold 2 "[ OK ]")" --- "Directory "$(drawtext bold 2 "${HOME_DIR}")" successfully created"
touch ${LOG_FILE} 
echo "$(drawtext bold 2 "[ OK ]")" --- "File "$(drawtext bold 2 "$LOG_FILE")" successfully created"
echo START System --- $( date +"%H-%M-%S_%d-%m-%Y") >> ${LOG_FILE} 
echo START System --- $( date +"%H-%M-%S_%d-%m-%Y")
# Update system
echo "Updating system... "
yum update -y --nogpgcheck 
echo "$(drawtext bold 2 "[ OK ]")" --- "System Updated"

# <----- Install Other Program ------>

#1. Install wget GIT
cd /${HOME_DIR}
yum install -y wget git --nogpgcheck 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "wget, GIT")" successfully installed"

#2. Install JAVA 1.8.0_162
#info: https://www.digitalocean.com/community/tutorials/how-to-install-java-on-centos-and-fedora
cd /${HOME_DIR} 
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm" 
rpm -ihv jdk-8u162-linux-x64.rpm 2>>${LOG_FILE}
rm -f jdk-8u162-linux-x64.rpm  2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "JAVA 1.8.0_162")" successfully installed"

#3. Install Apache-Maven
cd /usr/java 
#info: https://tecadmin.net/install-apache-maven-on-centos/
wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar -zxvf apache-maven-3.5.2-bin.tar.gz 2>>${LOG_FILE}
rm -f apache-maven-3.5.2-bin.tar.gz 2>>${LOG_FILE}
ln -sf ${MAVEN_HOME}/bin/mvn /usr/bin/mvn

echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "Apache-Maven")" successfully installed"

#4. Installing MySQL
#info: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-centos-7
cd /${HOME_DIR} 
wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
rpm -ivh mysql57-community-release-el7-9.noarch.rpm 
yum -y install mysql-server 2>>${LOG_FILE}
rm -f mysql57-community-release-el7-9.noarch.rpm 2>>${LOG_FILE}
#Upgrading MySQL
yum update mysql-server
echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "MySQL")" successfully installed"
echo "Starting mysql-server"
service mysqld start 2>>${LOG_FILE}
service mysqld status  2>>${LOG_FILE}
#Activating System Environment Variables
cd  /etc/profile.d
source vars.sh
mvn -v 2>>${LOG_FILE}
echo "$(drawtext bold 2 "[ OK ]")" ---  "Create System Environment Variables"

echo "$(drawtext bold 2 ""!!Congratulations SWorkSpace CONFIGURATED!!"  - $( date +"%H-%M-%S_%d-%m-%Y")")"  

# <----- WorkSpace configurated ------>
