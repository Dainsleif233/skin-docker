FROM php:8.1-fpm-alpine
LABEL maintainer="dainsleif@yeah.com"
ARG VERSION

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    pdo_mysql \
    pdo_pgsql \
    gd \
    zip \
    redis \
    intl
RUN wget https://github.com/bs-community/blessing-skin-server/releases/download/${VERSION}/blessing-skin-server-${VERSION}.zip -O /tmp/bs.zip \
    && unzip /tmp/bs.zip -d /var/www/html/ \
    && rm /tmp/bs.zip
RUN sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/^CACHE_DRIVER=.*/CACHE_DRIVER=redis/' .env.example \
    && sed -i 's/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/' .env.example \
    && sed -i 's/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/' .env.example \
    && sed -i 's/^REDIS_HOST=.*/REDIS_HOST=redis/' .env.example \
    && printf "\nPLUGINS_REGISTRY=https://d2jw1l0ullrzt6.cloudfront.net/registry_{lang}.json\n" >> .env.example
RUN mkdir -p data-example/public data \
    && mv storage data-example/ \
    && mv .env.example data-example/.env \
    && mv public/app data-example/public/ \
    && mv public/lang data-example/public/ \
    && mv public/plugins data-example/public/ \
    && mv public/meta.js data-example/public/ \
    && mv public/sw.js data-example/public/ \
    && cp public/index.php data-example/public/
RUN ln -s data/storage storage \
    && ln -s data/.env .env \
    && ln -s ../data/public/app public/app \
    && ln -s ../data/public/lang public/lang \
    && ln -s ../data/public/plugins public/plugins \
    && ln -s ../data/public/meta.js public/meta.js \
    && ln -s ../data/public/sw.js public/sw.js

RUN chown -R www-data:www-data /var/www/html
COPY --chmod=0755 entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
VOLUME ["/var/www/html/data", "/var/www/html/plugins"]
