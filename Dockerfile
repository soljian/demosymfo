# PHP DEV
FROM soljian/php:7.2-fpm-buster-hc-wfi as dev
LABEL maintainer='maxime.verrier@sgs.com'

WORKDIR /var/www

RUN mkdir /home/appuser && \
    chown 1000:1000 /home/appuser && \
    groupadd -r -g 1000 appuser && \
    useradd -r -u 1000 -b /home -g appuser appuser && \
    chown -R 1000:1000 /var/www/
USER appuser

COPY --chown=1000:1000 . ./
RUN mkdir /var/www/tests_logs || true

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer global require "symfony/flex" --prefer-dist --no-progress --no-suggest --classmap-authoritative; \
	composer clear-cache
ENV PATH="${PATH}:/root/.composer/vendor/bin"

RUN composer install --prefer-dist --no-dev --no-progress --no-suggest --optimize-autoloader ; \
    composer clear-cache ; \
    chmod 755 -R var/log/; \
    chmod 755 -R var/cache/

CMD composer install --no-progress --no-suggest ; \
	php bin/console cache:clear ; \
    php-fpm

# PHP PROD
FROM dev as prod
# UNIQUEMENT EN CAS DE DB LOCALE MARIADB
CMD php-fpm

# NGINX
FROM soljian/nginx:plugnplay as nginx
COPY --from=dev /var/www/public/ ./public