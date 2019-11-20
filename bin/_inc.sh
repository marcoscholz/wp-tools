#!/bin/bash

#hash generator
function genPass(){ 
	local l=$1
	[ "$l" == "" ] && l=32
	
	if [ $(type pwgen &> /dev/null) ]; then
            echo 'generating password with pwgen'
	   < pwgen -Bync1 $l
            return
    fi
    
    < /dev/urandom tr -dc '123456789!@#%+*~?qwertzuiopasdfghjklyxcvbnmQWERTZUIOPASDFGHJKLYXCVBNM' | head -c ${l} | xargs 
}



function copyPublicKeys(){
	local USERNAME=$1
	local HOMEPATH=/home/$USERNAME
	
	[ "$USERNAME" == "root" ] && HOMEPATH=/root
	
	mkdir -p $HOMEPATH/.ssh
	touch $HOMEPATH/.ssh/authorized_keys
	chown -R $USERNAME $HOMEPATH/.ssh
	chmod 700 -R $HOMEPATH/.ssh
	chmod 600 $HOMEPATH/.ssh/authorized_keys
	
	echo -e "copying public keys for user $USERNAME"
	for FILE in /vagrant/.publickeys/*.pub; do
		[ -e "$FILE" ] || continue
		echo -e "copying: $FILE ..."
		cat $FILE >> $HOMEPATH/.ssh/authorized_keys
	done
	systemctl restart ssh
}



function createApacheConfig(){
	USERNAME=$1
	HOMEDIR=/home/$USERNAME
	DocumentRoot=/var/www/$USERNAME
	ServerIP="85.214.88.136:80 10.9.8.7:80"
	ServerName="skat-hansa.de"
	ServerAdmin="marco.scholz@hamburg.de"
	
	echo -e "...creating apache config"
    echo -e "<VirtualHost ${ServerIP}>
	ServerName ${ServerName}
	ServerAdmin ${ServerAdmin}
	ErrorLog ${HOMEDIR}/www/log/error.log
    CustomLog ${HOMEDIR}/www/log/access.log combined
		
	DocumentRoot ${DocumentRoot}
	<Directory ${DocumentRoot}>
        Require all granted
        AllowOverride all
    </Directory>
	
	# Deny access to important files - ab Apache 2.4
	<FilesMatch \"(\.htaccess|\.htpasswd|wp-config\.php)\">
		Require all denied
	</FilesMatch>

	# Rewrite Rules
	<IfModule mod_rewrite.c>
		RewriteEngine on
		RewriteOptions inherit
	
		# Block .svn, .git
		RewriteRule \.(svn|git)(/)?$ - [F]
	</IfModule>
	
    # Recommended: XSS protection
    <IfModule mod_headers.c>
        Header set X-XSS-Protection \"1; mode=block\"
        Header always append X-Frame-Options SAMEORIGIN
    </IfModule>

	</VirtualHost>" > $HOMEDIR/www/apache.conf
	
	echo -e "index: ${user}" > $HOMEDIR/www/html/index.html
	echo -e "...creating symlink for apache.conf"
	ln -s $HOMEDIR/www/apache.conf /etc/apache2/sites-available/${USERNAME}.conf
	
	a2ensite ${USERNAME}.conf
	a2dissite 000-default.conf
	service apache2 reload
}



function createSSL {
	ssh root@$HOST "certbot --apache -w $WEB_DIR/$DOMAIN -d $DOMAIN -d www.$DOMAIN -m $CERT_MAIL --agree-tos -n"
}