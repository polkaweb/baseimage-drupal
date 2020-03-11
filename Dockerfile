FROM drupal:7.69

# Install Memcached for php 7
RUN apt-get update && apt-get install -y \
     zlib1g-dev \    
 && rm -rf /var/lib/apt/lists/* \
 && pecl install memcache \
 && docker-php-ext-enable memcache
    
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean \
 && curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -

ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail \
 && cp /root/go/bin/mhsendmail /usr/bin/mhsendmail

# Add composer.
ENV COMPOSER_VERSION 1.10.0
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV PATH "/${COMPOSER_HOME}/vendor/bin:${PATH}"
RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/d2c7283f9a7df2db2ab64097a047aae780b8f6b7/web/installer \
 && php -r " \
    \$signature = 'e0012edf3e80b6978849f5eff0d4b4e4c79ff1609dd1e613307e16318854d24ae64f26d17af3ef0bf7cfb710ca74755a'; \
    \$hash = hash('sha384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
      unlink('/tmp/installer.php'); \
      echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
      exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
 && composer --ansi --version --no-interaction \
 && rm -f /tmp/installer.php \
 && find /tmp -type d -exec chmod -v 1777 {} +

# Add utils.
RUN apt-get update && apt-get install -y \
    mariadb-client \
    nano \
    unzip \
 && rm -rf /var/lib/apt/lists/*

# Add Drush.
ENV DRUSH_VERSION 8.3.0
RUN composer global require "drush/drush:${DRUSH_VERSION}" \
 && drush @none dl registry_rebuild-7.x -y \
 && drush cc drush

# Add configuration overrides.
COPY *.ini /usr/local/etc/php/conf.d/