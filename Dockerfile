FROM php:7.4-apache

RUN docker-php-ext-install -j "$(nproc)" opcache

RUN set -eux \
   && apt-get update \
   && apt-get install -y libzip-dev zlib1g-dev \
  #  && apt-get install -y lsb-release software-properties-common
  #  && add-apt-repository "deb http://archive.ubuntu.com/ubuntu " "$(lsb_release -sc)" " universe" \
  #  && apt-get update \
  #  && apt-get install -y php7.4-mbstring \
   && docker-php-ext-install zip

RUN pecl install grpc-1.44.0
RUN pecl install protobuf

RUN set -ex; \
  { \
    echo "; Cloud Run enforces memory & timeouts"; \
    echo "memory_limit = -1"; \
    echo "max_execution_time = 0"; \
    echo "; File upload at Cloud Run network limit"; \
    echo "upload_max_filesize = 32M"; \
    echo "post_max_size = 32M"; \
    echo "; Configure Opcache for Containers"; \
    echo "opcache.enable = On"; \
    echo "opcache.validate_timestamps = Off"; \
    echo "; Configure Opcache Memory (Application-specific)"; \
    echo "opcache.memory_consumption = 32"; \
  } > "$PHP_INI_DIR/conf.d/cloud-run.ini"

# May need to change the hash as it changes here: https://getcomposer.org/download/
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Composer Installer verified'; } else { echo 'Composer Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');"

# Copy in custom code from the repository.
WORKDIR /var/www/html

# Use the PORT environment variable in Apache configuration files.
# https://cloud.google.com/run/docs/reference/container-contract#port
RUN sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Configure PHP for development.
# Switch to the production php.ini for production operations.
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# https://github.com/docker-library/docs/blob/master/php/README.md#configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN echo "extension=grpc.so" >> "$PHP_INI_DIR/php.ini"
RUN echo "extension=protobuf.so" >> "$PHP_INI_DIR/php.ini"

# RUN chmod 644 /var/www/html/.htaccess
RUN chmod -R 755 /var/www/html/
RUN a2enmod rewrite
# RUN a2enmod ssl
# RUN a2ensite default-ssl
# RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem -subj "/C=AT/ST=Vienna/L=Vienna/O=Security/OU=Development/CN=example.com"
RUN echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf
RUN service apache2 restart

EXPOSE 8080 80

# ENTRYPOINT ["index.php"]
# RUN php -S localhost:8080
