FROM ubuntu:trusty
MAINTAINER Ibn Saeed <ibnsaeed@gmail.com>

# Update apt sources
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list

# Update the package repository
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \ 
	DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget


# Install PHP 5.5
RUN apt-get update; apt-get install -y git apache2 supervisor libapache2-mod-php5 php5-gd php-pear php5-cli php5 php5-mcrypt php5-curl php5-pgsql php5-mysql
 
# Composer
ENV COMPOSER_HOME /root/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version
#RUN mv /usr/local/bin/composer.phar /usr/local/bin/composer

# Drush.
RUN composer global require drush/drush:6.*
# Setup the symlink
RUN ln -sf $COMPOSER_HOME/vendor/bin/drush.php /usr/local/bin/drush
# Display which version of Drush was installed
RUN drush --version

# Override default apache conf
#COPY conf/apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY conf/001-docker.conf /etc/apache2/sites-available/
RUN ln -s /etc/apache2/sites-available/001-docker.conf /etc/apache2/sites-enabled/

# Enable apache rewrite module and vhost_alias
RUN a2enmod rewrite

# Restart apache2 because we changed configuration directives in php.ini
RUN service apache2 restart

# Set Apache environment variables (can be changed on docker run with -e)
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www/html
ENV APACHE_APPLICATION_ENV development


# Add image configuration and scripts
COPY scripts/start.sh /start.sh
COPY scripts/run.sh /run.sh
RUN chmod 755 /*.sh
COPY conf/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf

# Configure /app folder
RUN mkdir -p /app && rm -fr /var/www && ln -s /app /var/www

# Source envvars
#RUN sudo /etc/apache2/envvars
RUN sudo apache2ctl -S


EXPOSE 80
CMD ["/run.sh"]
