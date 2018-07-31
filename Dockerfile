FROM php:7.1-apache-jessie

RUN echo 'deb http://ftp.fr.debian.org/debian/ jessie main contrib non-free' > /etc/apt/sources.list && \
    echo 'deb-src http://ftp.fr.debian.org/debian/ jessie main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://security.debian.org/ jessie/updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb-src http://security.debian.org/ jessie/updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://ftp.fr.debian.org/debian/ jessie-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb-src http://ftp.fr.debian.org/debian/ jessie-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://ftp.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/backports.list
RUN apt-get -y update && apt-get install -y wget apt-transport-https
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub |  apt-key add -
RUN wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg
RUN echo 'deb http://ftp.utexas.edu/dotdeb/ stable all' > /etc/apt/sources.list.d/dotdeb.list && \
    echo 'deb-src http://ftp.utexas.edu/dotdeb/ stable all' > /etc/apt/sources.list.d/dotdeb.list
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install
RUN apt-get update && apt-get upgrade -y && apt-get install -y -t jessie-backports libpq-dev zlib1g-dev \
    libgconf-2-4 libx11-6 libfontconfig nano xvfb \
    jq bc && apt-get install -y nodejs libpq-dev libffi-dev libssl-dev libgmp3-dev libmpfr-dev libmpc-dev

RUN DEBIAN_FRONTEND=noninteractive apt install -y locales && \
    sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="fr_FR.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=fr_FR.UTF-8
ENV LANG fr_FR.UTF-8

# Setup apache
COPY etc/symfony.conf /etc/apache2/sites-available/
RUN mkdir -p /var/log/symfony
RUN chown -R www-data. /var/log/symfony/
RUN rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pgsql pdo_pgsql zip
RUN pecl install xdebug-2.5.3 && docker-php-ext-enable xdebug

#setup composer
RUN wget https://composer.github.io/installer.sig -O - -q | tr -d '\n' > installer.sig
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN php -r "unlink('composer-setup.php'); unlink('installer.sig');"

RUN a2enmod rewrite
RUN a2dissite 000-default.conf
RUN a2ensite symfony.conf

WORKDIR /mnt/apps/symfony
RUN chown -R www-data:www-data /var/log/symfony
COPY docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-entrypoint