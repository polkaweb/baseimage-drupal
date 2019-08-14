FROM php:7.1-alpine as builder

# Ensure build tools are installed
RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
      curl \
      git \
      unzip \
      openssh-client

# Install Drush.
ENV DRUSH_VERSION=8.3.0
RUN set -xe \
    && curl -fsSL -o /usr/local/bin/drush "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" \
    && chmod +x /usr/local/bin/drush


FROM php:7.2-apache-stretch

RUN a2enmod rewrite \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
      libfreetype6-dev \
      libjpeg-dev \
      libpng-dev \
      libpq-dev \
      libzip-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd \
      --with-freetype-dir=/usr \
      --with-jpeg-dir=/usr \
      --with-png-dir=/usr \
    && docker-php-ext-install -j$(nproc) \
      gd \
      opcache \
      pdo \
      pdo_mysql \
      zip \
    && rm -Rf /tmp/*

# Copy drush
COPY --from=builder /usr/local/bin/drush /usr/local/bin/drush

# Add drush registry rebuild
RUN drush @none dl registry_rebuild-7.x -y \
    && drush cc drush

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      mariadb-client \
      nano \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /tmp/*

WORKDIR /var/www/html

ENV DRUPAL_VERSION 7.67
ENV DRUPAL_MD5 78b1814e55fdaf40e753fd523d059f8d

RUN set -eux \
    && curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
    && echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c - \
    && tar -xz --strip-components=1 -f drupal.tar.gz \
    && rm drupal.tar.gz \
    && chown -R www-data:www-data sites modules themes

# Copy configuration overrides.
COPY *.ini /usr/local/etc/php/conf.d/
