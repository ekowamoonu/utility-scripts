#!/bin/bash

##setting up a new ec2 instance for laravel  THIS WORKS with amazon linux 2
# get admin privileges
sudo su

# install httpd (Linux 2 version)
yum update -y
yum install -y httpd.x86_64

#forAmazon linux 2023, you will need to install php in a different way since it is no longer available
#also amazin linux now uses dnf instead of yum
yum install amazon-linux-extras -y
#sudo amazon-linux-extras | grep php 
amazon-linux-extras enable php8.0
yum clean metadata 
yum install php php-common php-pear -y
yum install php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip} -y

#all config files have been moved to s3 (php.ini, httpd.conf)
#so all we need to do is to download these file during the initialising of the ec2 instance
#change /etc/php.ini settings
#nano /etc/php.ini
#max execution time should be = 60
#memory limit should be = 1024M

#configure apache server to point to the laravel directory
#nano /etc/httpd/conf/httpd.conf

#udpate keepalive settings in /etc/httpd/conf/httpd.conf with the following
#MaxKeepAliveRequests 500
#KeepAlive On
#KeepAliveTimeout 2

#copy this code to the last end of the file
# Alias / /var/www/html/my-site/public/
# <Directory "/var/www/html/my-site/public">
#       AllowOverride All
#       Order allow,deny
#       allow from all
# </Directory>

####

#pull php.ini and httpd.conf config files from s3
aws s3 cp s3://my-bucket/ec2_production_config_files/php.ini /etc/php.ini
aws s3 cp s3://my-bucket/ec2_production_config_files/httpd.conf /etc/httpd/conf/httpd.conf

#setting up laravel
yum install git -y
cd /var/www/html
git clone https://repo@github.com/username/repo.git 


#after that save the file and go on to edit the htaccess file as well
#this is usually already done from the repo
#nano /var/www/html/my-site/public/.htaccess 

#Then add RewriteBase / just below RewriteEngine On

#Next, is to upload get the production .env file
#make sure to allow for chmod -r 777 permissions to the destination folder

#Next, give apache write access to the storage folder, else laravel will throw a wirte permission error
chmod -R 775 /var/www/html/my-site/storage
chown -R www-data:www-data /var/www/html/my-site/storage

systemctl restart httpd.service
systemctl enable httpd.service

#composer setup
#yum install wget -y (usually already installed on amazon linux)
cd /var/www/html/my-site
wget https://getcomposer.org/composer.phar
#sudo mv composer.phar /usr/local/bin/composer
#chmod +x /usr/local/bin/composer

export COMPOSER_HOME="$HOME/.config/composer";

#you can confirm installation by running php composer.phar
export COMPOSER_ALLOW_SUPERUSER=1;
php composer.phar install --no-dev

aws ssm get-parameter --name "EC2_PRODUCTION_ENV" --region "us-east-1" --query Parameter.Value | sed -e 's/^"//' -e 's/"$//' -e 's/\\n/\n/g' -e 's/\\//g' > "/var/www/html/my-site/.env"
