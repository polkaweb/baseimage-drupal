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


FROM drupal:7.67

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

# Copy configuration overrides.
COPY *.ini /usr/local/etc/php/conf.d/
