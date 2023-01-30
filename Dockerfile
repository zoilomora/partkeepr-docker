FROM php:5.6-apache

LABEL maintainer="Zoilo Mora <zoilo.mora@hotmail.com>"
LABEL version="1.4.0"

ENV PARTKEEPR_VERSION 1.4.0

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        bsdtar \
        libldap2-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libfreetype6-dev \
        libicu-dev \
        cron && \
    rm -r /var/lib/apt/lists/*

RUN docker-php-ext-configure \
        ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-configure \
        gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) \
        zip ldap gd bcmath intl pdo pdo_mysql && \
    \
    pecl install apcu-4.0.8 && \
    docker-php-ext-enable apcu

RUN cd /var/www/html && \
    curl -sL https://downloads.partkeepr.org/partkeepr-${PARTKEEPR_VERSION}.tbz2 \
        | bsdtar --strip-components=1 -xvf- && \
    chown -R www-data:www-data /var/www/html && \
    a2enmod rewrite

COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY php.ini /usr/local/etc/php/php.ini
COPY docker-php-entrypoint mkparameters parameters.template /usr/local/bin/
COPY crontab /etc/cron.d/partkeepr

VOLUME ["/var/www/html/data", "/var/www/html/web"]

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]
