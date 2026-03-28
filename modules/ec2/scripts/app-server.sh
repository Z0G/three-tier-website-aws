#!/bin/bash
exec > /var/log/app-server-setup.log 2>&1
set -x

# Update system
yum update -y

# Install Apache web server
yum install -y httpd httpd-tools mod_ssl

# Enable and start Apache
systemctl enable httpd
systemctl start httpd

# Install PHP and necessary extensions
yum install -y php php-common php-pear php-cli php-cgi php-curl php-mbstring php-gd php-mysqlnd php-gettext php-json php-xml php-fpm php-intl php-zip

# Install MySQL Client
yum install -y mysql

# Create /var/www/html directory
mkdir -p /var/www/html

# Mount EFS
echo "${efs_dns_name}:/ /var/www/html nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab
mount -a

# Set permissions
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
chown apache:apache -R /var/www/html

# Restart Apache
systemctl restart httpd

echo "Application server configuration complete"
