FROM debian:stretch
MAINTAINER Ean J. Price <ean@pricepaper.com>

# Install some deps and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            curl \
            build-essential \
            adduser \
            lsb-base \
            postgresql-client \
            python3-setuptools \
            python3-pip \
            python3-pil \
            python3-wheel \
            gnupg \
            python3-dev \
            libxslt1-dev \
            libxslt-dev \
            zlib1g-dev \
            libldap2-dev \
            libsasl2-dev \
            libxml2-dev \
            git \
            locales \
            xfonts-75dpi \
        && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 

ENV LANG en_US.utf8

# install newer node and lessc (mostly for less compatibility)
RUN set -x; \
        curl -sL https://deb.nodesource.com/setup_6.x | bash - \
        && apt-get install -y nodejs

RUN npm install -g less \
    && npm install -g less-plugin-clean-css \
    && ln -s `which nodejs` /bin/node \
    && ln -s `which lessc` /bin/lessc

# Install wkhtmlpdf and libraries
COPY files/wk_install/*.deb /tmp/wk_install/
RUN set -x; \
   dpkg -i /tmp/wk_install/libpng12-0_1.2.50-2+deb8u3_amd64.deb \
   /tmp/wk_install/libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb \
   && apt install -y /tmp/wk_install/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
   && rm -rf /tmp/wk_install

# Install Odoo
COPY ./odoo.conf /etc/odoo/
ENV ODOO_VERSION 11.0
RUN set -x; \
        cd /opt \
        && git clone --depth 1 --branch=$ODOO_VERSION http://github.com/odoo/odoo.git \
        && cd odoo \
        && rm -rf .git .github \
        && pip3 install --no-cache-dir -r requirements.txt \
        && pip3 install --no-cache-dir psycogreen \
        && pip3 install --no-cache-dir phonenumbers \
        && pip3 install --no-cache-dir pyOpenSSL \
        && bash debian/postinst configure \
        && apt-get purge -y \
            gcc \
            libsasl2-dev \
            libldap2-dev \
            build-essential \
            libssl-dev \
            gnupg \
            python3-dev \
            libxslt-dev \
            zlib1g-dev \
            libxml2-dev \
            git \
        && apt-get -y autoremove \
        && rm -rf /var/lib/apt/lists/*

# Install GeoIP database in case we need it for Odoo
RUN set -x; \
        mkdir -p /usr/share/GeoIP \
        && curl -sL http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
            | gunzip -c > /usr/share/GeoIP/GeoLiteCity.dat

# Copy entrypoint script and Odoo configuration file as well as include Odoo in $PATH
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY ./odoo.sh /etc/profile.d/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/{enterprise,custom}-addons for users addons
RUN mkdir -p /mnt/enterprise-addons \
        && chown -R odoo /mnt/enterprise-addons
RUN mkdir -p /mnt/custom-addons \
        && chown -R odoo /mnt/custom-addons
RUN mkdir -p /var/lib/odoo \
        && chown -R odoo /var/lib/odoo
VOLUME ["/var/lib/odoo", "/mnt/custom-addons", "/mnt/enterprise-addons"]]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo-bin"]
