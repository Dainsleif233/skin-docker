FROM php:8.1-fpm-alpine
LABEL maintainer="dainsleif@yeah.com"
ARG VERSION

# ============================================================================
# CVE-2026-109618 / CVE-2026-109619 官方 8.1 backport 补丁
# - 用镜像自带的 $PHP_URL / $PHP_SHA256 取回与官方二进制完全一致的 8.1.34 源码
# - 按 docker-library 官方构建顺序先打 3 个 out-of-tree 补丁
# - 再叠加 php-src 分支 PHP-8.1-CVE-2026-109618-109619 的补丁
#   (commit 1d7dec178a094e6e75b229ce22754045f8c6070a)
# - 原地重建 /usr/local 下的 PHP：版本号仍是 8.1.34，php-fpm / 扩展目录 /
#   www-data 用户 / php.ini 位置全部不变，只是把有洞的二进制换掉
# 代价：镜像构建多约 5~15 分钟（一次编译）。日常 no-cache 重建才会有这个开销。
# ============================================================================
COPY cve-2026-109618-109619.patch /tmp/cve.patch

RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        argon2-dev \
        coreutils \
        curl-dev \
        gnu-libiconv-dev \
        libsodium-dev \
        libxml2-dev \
        linux-headers \
        oniguruma-dev \
        openssl-dev \
        patch \
        patchutils \
        pax-utils \
        readline-dev \
        sqlite-dev \
    ; \
    rm -vf /usr/include/iconv.h; \
    export \
        CFLAGS="$PHP_CFLAGS" \
        CPPFLAGS="$PHP_CPPFLAGS" \
        LDFLAGS="$PHP_LDFLAGS" \
    ; \
    mkdir -p /usr/src; \
    cd /usr/src; \
    curl -fsSL -o php.tar.xz "$PHP_URL"; \
    echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
    mkdir -p /usr/src/php; \
    tar -xJf php.tar.xz -C /usr/src/php --strip-components=1; \
    rm -f php.tar.xz; \
    cd /usr/src/php; \
    curl -fL 'https://github.com/php/php-src/commit/577b8ae4226368e66fee7a9b5c58f9e2428372fc.patch?full_index=1' -o 11678.patch; \
    echo '6edc20c3bb3e7cc13515abce7f2fffa8ebea6cf7469abfbc78fcdc120350b239 *11678.patch' | sha256sum -c -; \
    patch -p1 < 11678.patch; \
    rm 11678.patch; \
    curl -fL 'https://github.com/php/php-src/commit/a5df26691d1b1f71b964b869510473a5d5413999.patch?full_index=1' -o 19131.patch; \
    echo 'c98c01c74d3a6da197116f8511b16fed361ca6bbb6a8af8df629a933f541c213 *19131.patch' | sha256sum -c -; \
    patch --reverse -p1 < 19131.patch; \
    rm 19131.patch; \
    curl -fL 'https://github.com/php/php-src/commit/67259e451d5d58b4842776c5696a66d74e157609.patch?full_index=1' -o 14834.patch; \
    echo 'ed10a1b254091ad676ed204e55628ecbd6c8962004d6185a1821cedecd526c0f *14834.patch' | sha256sum -c -; \
    filterdiff -x '*/NEWS' 14834.patch | patch -p1; \
    rm 14834.patch; \
    echo 'c85ad0fddcbff7f2318617eeaa54d271135463b5bf70a01228447e3ed78de96e */tmp/cve.patch' | sha256sum -c -; \
    patch -p1 --fuzz=3 < /tmp/cve.patch; \
    rm -f /tmp/cve.patch; \
    \
    grep -q 'PS(rfc1867_enabled) || true' ext/session/session.c; \
    \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
        --build="$gnuArch" \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --with-mhash \
        --with-pic \
        --enable-ftp \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium=shared \
        --with-pdo-sqlite=/usr \
        --with-sqlite3=/usr \
        --with-curl \
        --with-iconv=/usr \
        --with-openssl \
        --with-readline \
        --with-zlib \
        --disable-phpdbg \
        --with-pear \
        $(test "$gnuArch" = 'riscv64-linux-musl' && echo '--without-pcre-jit') \
        --disable-cgi \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
    ; \
    make -j "$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    find /usr/local -type f -perm '/0111' -exec sh -euxc 'strip --strip-all "$@" || :' -- '{}' +; \
    make clean; \
    cp -v php.ini-* "$PHP_INI_DIR/"; \
    cd /; \
    rm -rf /usr/src/php; \
    runDeps="$(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }')"; \
    apk add --no-cache $runDeps; \
    apk del --no-network .build-deps; \
    pecl update-channels; \
    rm -rf /tmp/pear ~/.pearrc; \
    php --version

# 扩展在打过补丁的 PHP 之上编译，避免与旧头文件/旧 ABI 混用
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
    && echo "php_admin_flag[session.upload_progress.enabled] = off" >> /usr/local/etc/php-fpm.d/www.conf \
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
