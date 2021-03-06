  FROM php:5.6-fpm
MAINTAINER Stéphane Cottin <stephane.cottin@vixns.com>

RUN curl -L -s http://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list

RUN apt-get update && apt-get -y dist-upgrade
RUN \
	apt-get install --no-install-recommends -y ca-certificates nginx-extras runit file re2c libicu-dev zlib1g-dev \
	libmcrypt-dev libmagickcore-dev libmagickwand-dev libmagick++-dev libjpeg-dev libpng12-dev libicu52 libmcrypt4 g++ \
  imagemagick git libssl-dev xfonts-base xfonts-75dpi libfreetype6-dev && \
  mkdir /usr/local/etc/php-fpm.d && \
	rm -rf /var/lib/apt/lists/*

RUN \
  curl -s -L -o /tmp/wkhtmltox.deb http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb && \
  dpkg -i /tmp/wkhtmltox.deb && rm /tmp/wkhtmltox.deb

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/lib && docker-php-ext-install sockets intl zip mbstring mcrypt gd

RUN pecl install imagick-beta && \
  echo "extension=imagick.so" >> "/usr/local/etc/php/conf.d/ext-imagick.ini" &&  \  
  echo "date.timezone=UTC" >> "/usr/local/etc/php/conf.d/timezone.ini" && \
  echo "zend_extension=opcache.so" >> "/usr/local/etc/php/conf.d/ext-opcache.ini" && \
  echo "opcache.enable_cli=1" >> "/usr/local/etc/php/conf.d/ext-opcache.ini" && \
  echo "opcache.memory_consumption=128" >> "/usr/local/etc/php/conf.d/ext-opcache.ini" && \
  echo "opcache.interned_strings_buffer=8" >> "/usr/local/etc/php/conf.d/ext-opcache.ini" && \
  echo "opcache.max_accelerated_files=4000" >> "/usr/local/etc/php/conf.d/ext-opcache.ini" && \
  echo "opcache.fast_shutdown=1" >> "/usr/local/etc/php/conf.d/ext-opcache.ini"

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# forward request and error logs to docker log collector
RUN ln -sf /proc/1/fd/1 /var/log/nginx/access.log
RUN ln -sf /proc/1/fd/2 /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /usr/local/etc/
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php-fpm.sh /etc/service/php-fpm/run
COPY nginx.sh /etc/service/nginx/run
COPY runsvdir-start.sh /usr/local/sbin/runsvdir-start

VOLUME ["/var/cache/nginx"]
EXPOSE 80

CMD ["/usr/local/sbin/runsvdir-start"]
