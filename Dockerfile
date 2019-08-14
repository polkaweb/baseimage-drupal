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


FROM php:7.1-apache

ARG DEBIAN_FRONTEND=noninteractive

RUN a2enmod rewrite \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
      libc-client-dev \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libkrb5-dev \
      libmcrypt-dev \
      libpng-dev \
      libyaml-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd \
      --with-freetype-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure imap \
      --with-kerberos \
      --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
      gd \
      iconv \
      imap \
      mbstring \
      mcrypt \
      pdo \
      pdo_mysql \
      zip \
    && pecl install \
      xdebug \
      yaml \
    && docker-php-ext-enable \
      xdebug \
      yaml

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
    && rm -Rf /tmp/* \
    && chown -Rf www-data: /var/www/html

# Copy configuration overrides.
COPY *.ini /usr/local/etc/php/conf.d/

EXPOSE 9000

WORKDIR /var/www/html
