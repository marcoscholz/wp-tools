#!/bin/bash

#credentials
USERNAME=$USER
[ "$USER" == "root" ] && [ ! -z ${3+x} ] && USERNAME=$3
[ "$USER" != "root" ] && [ ! -z ${3+x} ] && echo -e "you can not install wp for another user" && exit

cat << EOF >> /home/$USERNAME/www/.credentials
wp_table_prefix="wp_h65_"
wp_charset="utf8"
wp_locale="de_DE"
wp_version="latest"
wp_url="$2"
wp_title="Skatclub Hansa Hamburg"
wp_adminuser="hansa"
wp_adminpass="$( genPass 8 )"
wp_adminmail="marco.scholz@hamburg.de"

wp_folder=/home/$USERNAME/www/html
EOF

source /home/$USERNAME/www/.credentials
rm -f $wp_folder/index*
echo -e "downloading latest wordpress..."
wp core download --locale=$wp_locale --version=$wp_version --skip-content --path=$wp_folder --allow-root

#create wp_config one folder !above wordpress installation
echo -e "creating wp_config"
wp config create --dbname="$db_name" \
                 --dbuser="$db_user" \
                 --dbpass="$db_password" \
                 --dbprefix="$wp_table_prefix" \
                 --dbcharset="$wp_charset" \
                 --locale=$wp_locale \
                 --skip-check \
                 --path=$wp_folder \
                 --allow-root
mv $wp_folder/wp-config.php $wp_folder/../wp-config.php
chmod 440 /home/$USERNAME/www/wp-config.php

echo -e "deleting superfluous files..."
rm $wp_folder/license.txt
rm $wp_folder/readme.html
rm $wp_folder/wp-config-sample.php

echo -e "installing wordpress"
wp core install --url=$wp_url --title="$wp_title" --admin_user="$wp_adminuser" --admin_password="$wp_adminpass" --admin_email="$wp_adminmail" --path=$wp_folder --allow-root

echo -e "installing language"
wp language core install $wp_locale --path=$wp_folder --allow-root
wp site switch-language $wp_locale --path=$wp_folder --allow-root
cd $wp_folder
				


#set file permissions
find $wp_folder -type d -exec chmod 755 {} \; #folders
find $wp_folder -type f -exec chmod 644 {} \; #files


wp theme install tiny-hestia --activate --allow-root



