FROM php:8.1-apache

ARG DEBIAN_FRONTEND=noninteractive

# Update and install useful tools and install important libaries

RUN apt-get -y update --fix-missing && \
    apt-get --no-install-recommends install -y apt-utils && \
    apt-get install -y libzip-dev && \
    apt-get install -y zip && \
    apt-get install -y libcurl4-openssl-dev && \
    apt-get install -y curl && \
    apt-get install -y git && \
    apt-get install -y openssl && \
    apt-get install -y libicu-dev && \
    apt-get install -y libsqlite3-dev && \
    apt-get install -y libsqlite3-0

RUN rm -rf /var/lib/apt/lists/*

# Configure PHP for Cloud Run.
# Precompile PHP code with opcache.
RUN docker-php-ext-install -j "$(nproc)" opcache
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

RUN docker-php-ext-install pdo_mysql && \
    docker-php-ext-install pdo_sqlite && \
    docker-php-ext-install bcmath && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install curl && \
    docker-php-ext-install zip && \
    docker-php-ext-install -j$(nproc) intl && \
    docker-php-ext-install pcntl

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Use the PORT environment variable in Apache configuration files.
# https://cloud.google.com/run/docs/reference/container-contract#port
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Enable apache module rewrite
RUN a2enmod rewrite headers

# Cleanup
RUN rm -rf /usr/src/*