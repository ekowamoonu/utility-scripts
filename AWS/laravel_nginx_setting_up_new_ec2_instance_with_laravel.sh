#!/bin/bash
sudo su
yum update -y
dnf install openssl php8.2 php8.2-fpm php8.2-cli php8.2-bcmath php8.2-mbstring php8.2-pdo php8.2-xml php8.2-zip php8.2-gd -y
dnf install php-mysqlnd
dnf install nginx -y
dnf install -y git
dnf install composer -y

#Setting up nginx
#TODO Need to overwrite the default nginx.conf file from s3 or something
#TODO Copy site server block conf to /etc/nginx/conf.d from s3 or something
nano /etc/nginx/conf.d/site.conf

#setting up laravel
cd /var/www
git clone https://username:pat@bitbucket.org/username/site.git
cd site

#Make sure that the user and group params in /etc/php-fpm.d/www.conf is also nginx
chown -R nginx:nginx /var/www/site/storage 
chmod -R 775 /var/www/site/storage 
chown -R nginx:nginx /var/www/site/bootstrap
chmod -R 775 /var/www/site/bootstrap

#You can copy your production env from AWs paramater store 
#aws ssm get-parameter --name "EC2_PRODUCTION_ENV" --region "us-east-1" --query Parameter.Value | sed -e 's/^"//' -e 's/"$//' -e 's/\\n/\n/g' -e 's/\\//g' > "/var/www/html/my-site/.env"

#install composer dependencies
composer install --no-dev

#You can move config files to S3 and copy them during initialisation
#so all we need to do is to download these file during the initialising of the ec2 instance
#aws s3 cp s3://my-bucket/config_files/php.ini /etc/php.ini
#or you can directly modify your php ini settings to suit your needs
#change /etc/php.ini settings
#nano /etc/php.ini
#max execution time should be = 60
#memory limit should be = 1024M


systemctl restart nginx
systemctl enable nginx




