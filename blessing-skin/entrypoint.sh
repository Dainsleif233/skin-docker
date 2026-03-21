#!/bin/sh
[ ! -d "data/storage" ] && cp -r data-example/storage data/
[ ! -d "data/public" ] && cp -r data-example/public data/
[ ! -f "data/.env" ] && cp data-example/.env data/

chown -R www-data:www-data data

if [ -f .env ] && ! grep -q "^APP_KEY=." .env; then
    php artisan key:generate
fi

php artisan queue:work & php-fpm
