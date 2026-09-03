# Le guide du groupe ne fixe pas la version PHP.
# Ajuster cette version à celle validée dans le projet commun si nécessaire.
FROM php:8.3-cli

RUN apt-get update \
    && apt-get install -y git unzip libzip-dev \
    && docker-php-ext-install pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
