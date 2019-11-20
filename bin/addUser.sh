#!/bin/bash

USERNAME=$2
HOMEDIR=/home/$USERNAME

echo -e "\n\n\n"
echo -e "New user: $USERNAME"
echo -e "---------------------------------------------------------------------------"

# User
echo -e "...adduser: $USERNAME"
adduser --ingroup www-data --disabled-password --gecos "" $USERNAME
mkdir $HOMEDIR/bin

# Folders
echo -e "...creating html folders"
mkdir $HOMEDIR/www
mkdir $HOMEDIR/www/html
mkdir $HOMEDIR/www/log
chown -R $USERNAME:www-data $HOMEDIR/www

# Database
echo -e "...creating database for user"
db_password=$( genPass 32 )
mysql --execute "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$db_password';"
mysql --execute "CREATE DATABASE $USERNAME; GRANT ALL PRIVILEGES ON $USERNAME.* TO '$USERNAME'@'localhost';"
mysql --execute "FLUSH PRIVILEGES;"

# Credentials
echo -e "db_host='localhost'
db_name='$USERNAME'
db_user='$USERNAME'
db_password='$db_password'" > $HOMEDIR/www/.credentials

# Permissions
chown -R $USERNAME $HOMEDIR

# Symlink webfolder 
#echo -e "...creating symlink to webfolder"
#ln -s $HOMEDIR/www/html /var/www/$USERNAME 

#copyPublicKeys $1
copyPublicKeys $USERNAME

#newUser $1
#copyPublicKeys $1
#createApacheConfig $1