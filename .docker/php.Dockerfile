FROM php:8.1-fpm

# environment arguments
ARG UID
ARG GID
ARG USER
ARG SMTP_EMAIL

ENV UID=${UID}
ENV GID=${GID}
ENV USER=${USER}

USER root

# Creating user and group
RUN getent group www || groupadd -g $GID www \
    && getent passwd $UID || useradd -u $UID -m -s /bin/bash -g www www

# Modify php fpm configuration to use the new user's priviledges.
RUN sed -i "s/user = www-data/user = 'www'/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = 'www'/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Installing php extensions
RUN apt-get update -y \
    && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libbz2-dev \
    libssl-dev \
    libicu-dev \
    zip \
    unzip \
    curl \
    msmtp \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd exif mbstring mysqli pdo pdo_mysql \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && rm -rf /var/lib/apt/lists/*

# Configure connection to mail sender container
COPY ./msmtp/.msmtprc /etc/msmtprc
RUN sed -i "s/#EMAIL#/$SMTP_EMAIL/" /etc/msmtprc

USER www

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
