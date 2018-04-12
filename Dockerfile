FROM debian:stretch
LABEL maintainer="Ean J Price <ean@pricepaper.com>"

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG en_US.utf8

# Install some deps and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y locales \
        && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
        && apt-get -y upgrade \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            python3-openssl \
            python3-pycountry \
            libssl1.0-dev \
            xz-utils \
            gnupg \
            python3-xlrd \
        && curl -o wkhtmltox.tar.xz -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
        && echo '3f923f425d345940089e44c1466f6408b9619562 wkhtmltox.tar.xz' | sha1sum -c - \
        && tar xvf wkhtmltox.tar.xz \
        && cp wkhtmltox/lib/* /usr/local/lib/ \
        && cp wkhtmltox/bin/* /usr/local/bin/ \
        && cp -r wkhtmltox/share/man/man1 /usr/local/share/man/ \
        && rm -rf wkhtmltox wkhtmltox.tar.xz \
        && pip3 install --no-cache-dir num2words xlwt phonenumbers

# Use nodesource nodejs because Debian's version isn't maintained
RUN set -x; \
        curl -sL https://deb.nodesource.com/setup_6.x | bash - \
        && apt-get install -y nodejs

# install newer node and lessc (mostly for less compatibility)
RUN npm install -g less \
    && npm install -g less-plugin-clean-css \
    && ln -s `which nodejs` /bin/node \
    && ln -s `which lessc` /bin/lessc

# Install Odoo
ENV ODOO_VERSION 11.0
COPY files/odoo_11.0+e.latest_all.deb /tmp/
RUN set -x; \
        apt install -y /tmp/odoo_11.0+e.latest_all.deb \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* /tmp/odoo_11*.deb

# Install GeoIP database in case we need it for Odoo
RUN set -x; \
        mkdir -p /usr/share/GeoIP \
        && curl -sL http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
            | gunzip -c > /usr/share/GeoIP/GeoLiteCity.dat

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
