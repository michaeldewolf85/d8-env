#!/bin/bash

# @file
# Build script for Vagrant D8 environment.

# @var HOSTNAME
# The hostname is specified in settings.yaml.
HOSTNAME=$1

# @var DOCROOT
# The hostname is specified in settings.yaml.
DOCROOT=$2

# We set DEBIAN_FRONTEND to noninteractive in order to bypass all prompts that
# require user input.
export DEBIAN_FRONTEND=noninteractive

# Fetch software dependencies.
apt-get update
apt-get install -y nginx mysql-server php5-fpm php5-mysql php5-cli

# Configure nginx virtual host for hostname via http and https.
mkdir -p /var/www
ln -s "/vagrant$DOCROOT" "/var/www/$HOSTNAME"
cp /etc/nginx/sites-available/default "/etc/nginx/sites-available/$HOSTNAME"
sed -i "s/root.*;/root \/var\/www\/$HOSTNAME;/g" "/etc/nginx/sites-available/$HOSTNAME"
sed -i "s/server_name.*;/server_name $HOSTNAME;/g" "/etc/nginx/sites-available/$HOSTNAME"
sed -i 's/[^\_]index.*;/index index.php index.html index.htm;/g' "/etc/nginx/sites-available/$HOSTNAME"
sed -i '/# pass the PHP/,/#\}/{/\(# pass the PHP\|#\tfastcgi_pass 127\)/b a;s/# *//; :a}' "/etc/nginx/sites-available/$HOSTNAME"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/cert.key -out /etc/nginx/cert.pem -subj "/C=US/ST=Massachusetts/L=Cambridge/O=Third and Grove/OU=Engineering/CN=$HOSTNAME"
sed -i '/^# HTTPS server/,/#\}/{/^# HTTPS server/b a;s/^# *//; :a}' "/etc/nginx/sites-available/$HOSTNAME"
ln -s "/etc/nginx/sites-available/$HOSTNAME" "/etc/nginx/sites-enabled/$HOSTNAME"
rm /etc/nginx/sites-enabled/default
chown -R www-data:www-data "/var/www/$HOSTNAME"
service nginx restart

curl -sS https://getcomposer.org/installer | php
mv /home/vagrant/composer.phar /usr/local/bin/composer
su - vagrant -c 'composer global require drush/drush:dev-master'
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> /home/vagrant/.bashrc
