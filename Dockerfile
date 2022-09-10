FROM ubuntu:22.04 as base

RUN apt update && apt -y install \
  software-properties-common \
  curl apt-transport-https \
  ca-certificates \
  gnupg

# Add Ondrej Sury's PPA for PHP
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

RUN apt update

# Install PHP 8.1
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt -y install \
  php8.1 \
  php8.1-common \
  php8.1-cli \
  php8.1-gd \
  php8.1-mysql \
  php8.1-mbstring \
  php8.1-bcmath \
  php8.1-xml \
  php8.1-fpm \
  php8.1-curl \
  php8.1-zip \
  tar \
  unzip \
  git

RUN rm -rf /var/lib/apt && \
  rm -rf /var/lib/dpkg && \
  rm -rf /var/lib/cache && \
  rm -rf /var/lib/log

FROM base as builder
ARG PTERODACTYL_PANEL_VERSION="latest"

WORKDIR /var/www/pterodactyl

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Download the Pterodactyl Panel
RUN curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/${PTERODACTYL_PANEL_VERSION}/download/panel.tar.gz
RUN curl -Lo checksum.txt https://github.com/pterodactyl/panel/releases/${PTERODACTYL_PANEL_VERSION}/download/checksum.txt

RUN sha256sum -c checksum.txt

# Unpack the Pterodactyl Panel
RUN tar -xzvf panel.tar.gz

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Change the owner of the files, recursively
RUN chown -R www-data:www-data /var/www/pterodactyl

FROM base as app

WORKDIR /var/www/pterodactyl
USER www-data

COPY --from=builder /var/www/pterodactyl /var/www/ptereodactyl
