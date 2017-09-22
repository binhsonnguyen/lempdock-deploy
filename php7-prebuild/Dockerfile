FROM php:fpm

RUN apt-get update && apt-get install -y libmcrypt-dev --no-install-recommends

RUN docker-php-ext-install mcrypt pdo pdo_mysql
