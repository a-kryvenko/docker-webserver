FROM php:8.1-fpm

ARG GID
ARG UID
ARG SMTP_HOST
ARG SMTP_PORT
ARG SMTP_EMAIL
ARG SMTP_PASSWORD

USER root

WORKDIR /var/www

RUN apt-get update -y \
    && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
    msmtp \
    zip \
    unzip \
    && docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable mysqli pdo pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

COPY ./.docker/msmtp/msmtprc /etc/msmtprc

RUN sed -i "s/#HOST#/$SMTP_HOST/" /etc/msmtprc \
        && sed -i "s/#PORT#/$SMTP_PORT/" /etc/msmtprc \
        && sed -i "s/#EMAIL#/$SMTP_EMAIL/" /etc/msmtprc \
        && sed -i "s/#PASSWORD#/$SMTP_PASSWORD/" /etc/msmtprc

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN getent group www || groupadd -g $GID www \
    && getent passwd $UID || useradd -u $UID -m -s /bin/bash -g www www

USER www

EXPOSE 9000

CMD ["php-fpm"]
