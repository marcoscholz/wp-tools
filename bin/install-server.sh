#!/bin/bash


#credentials
db_root_password=$( genPass 32 )
echo -e "db_root_password=$db_root_password\n" >~/.credentials

echo -e "\n\n\n\n\n\n"
echo -e "installing the server..."
echo -e "this will take some time..."

echo -e "\n\n\n"
echo -e "1 | install updates and basic software"
echo -e "---------------------------------------------------------------------------"

#Set timezone
echo -e 'changing timezone...'
timedatectl set-timezone Europe/Berlin > /dev/null 2>&1

# system upgrades
echo -e 'updating system...'
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt dist-upgrade -y > /dev/null 2>&1

# base packages
echo -e 'installing base packages...'
apt -y install pwgen jq > /dev/null 2>&1
apt -y install vim nano zip unzip > /dev/null 2>&1
apt -y install htop mytop > /dev/null 2>&1
apt -y install git dos2unix > /dev/null 2>&1
apt -y install putty-tools openssl certbot > /dev/null 2>&1


echo -e "\n\n\n"
echo -e "2 | config ssh and copy public keys"
echo -e "---------------------------------------------------------------------------"
copyPublicKeys root


echo -e "\n\n\n"
echo -e "3 | firewall configuration"
echo -e "---------------------------------------------------------------------------"
echo -e "installing ufw firewall..."
apt install ufw > /dev/null 2>&1
echo -e "setting up firewall rules..."
ufw allow 22
ufw allow 443
ufw allow 8080
echo -e "enableling firewall..."
ufw enable


echo -e "\n\n\n"
echo -e "4 | apache is getting configured"
echo -e "---------------------------------------------------------------------------"

#apache2 & php
echo -e "installing apache..."
apt -y install apache2 php > /dev/null 2>&1
apt -y install php-xdebug php-soap php-intl php-curl php-zip php-mysql > /dev/null 2>&1
	
# php.ini changes
echo -e "configuring php.ini..."
sed -i s/"max_execution_time = .*"/"max_execution_time  = 300/" 	/etc/php/7.2/apache2/php.ini
sed -i s/"memory_limit = .*"/"memory_limit = 1024M/" 				/etc/php/7.2/apache2/php.ini
sed -i s/"post_max_size = .*"/"post_max_size = 64M/"				/etc/php/7.2/apache2/php.ini
sed -i s/";extension=php_soap.*"/"extension=php_soap.dll/" 			/etc/php/7.2/apache2/php.ini
sed -i s/"upload_max_filesize = .*"/"upload_max_filesize = 64M/" 	/etc/php/7.2/apache2/php.ini

# apache2 config
echo -e "activating apache modules..."
a2enmod rewrite
a2enmod headers
a2enmod expires
a2enmod deflate
a2enmod setenvif


echo -e "\n\n\n"
echo -e "5 | mariadb is getting configured"
echo -e "---------------------------------------------------------------------------"

# install mysql
echo -e "installing mariaDB..."
apt -y install mariadb-server > /dev/null 2>&1

#mysql_secure_installation
echo -e "security setting for database..."
mysql_secure_installation  <<EOF > /dev/null
n
$db_root_password
$db_root_password
y
y
y
y
y
EOF
service mysql restart


echo -e "\n\n\n"
echo -e "6 | installing wordpress CLI"
echo -e "---------------------------------------------------------------------------"
#wp-cli
echo -e "\nfetching wp-cli..."
wget -nv https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
echo -e "\nmaking wp-cli executeable..."
chmod +x /usr/local/bin/wp
#https://gist.github.com/GAS85/990b46a3a9c2a16c0ece4e48ebce7300