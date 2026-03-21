FROM alpine
LABEL maintainer="dainsleif@yeah.com"

RUN apk add --no-cache lighttpd
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

EXPOSE 80
VOLUME ["/var/www/html/public"]
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
