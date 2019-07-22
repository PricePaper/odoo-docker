FROM python:3.7-stretch
LABEL maintainer="Ean J Price <ean@pricepaper.com>"
ARG gitpassword=foobar

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
            git \
            gosu \
            dumb-init \
            libssl1.0-dev \
            xz-utils \
            gnupg \
            build-essential \
            vim-tiny \
            libxslt1-dev \
            libxslt-dev \
            zlib1g-dev \
            libldap2-dev \
            libsasl2-dev \
            libxml2-dev \
        && curl -o wkhtmltox.deb -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
        && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

RUN set -x; \
        echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
        && curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
            apt-key add - \
        && apt-get update \
        && apt-get install -y postgresql-client-10 \
        && rm -rf /var/lib/apt/lists/* 

RUN set -x; \
        pip3 install --no-cache-dir pyOpenSSL gnupg phonenumbers boto3 pyasn1-modules PyDrive \
        && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
        && apt-get install -y nodejs \
        && npm install -g less \
        && npm install -g less-plugin-clean-css \
        && ln -s `which nodejs` /bin/node \
        && ln -s `which lessc` /bin/lessc \
        && rm -rf /var/lib/apt/lists/* 

## Install Odoo
ENV ODOO_VERSION 12.0
RUN set -x; \
  cd / \
  && git clone -b $ODOO_VERSION --depth=1 https://github.com/odoo/odoo.git \
  && rm -rf /odoo/.git /odoo/.github \
  && pip3 install --no-cache-dir -e /odoo \
  && git clone -b $ODOO_VERSION --depth=1 https://ejprice:$gitpassword@github.com/odoo/enterprise.git \
  && rm -rf /enterprise/.git /enterprise/.github \
  && useradd -c "Odoo User" -u 23789 -d /odoo -m odoo \
  && chown -R odoo:odoo /odoo /enterprise

# Install fbprophet after Odoo to prevent multiple layers of Python libraries
RUN pip3 install --compile --no-cache-dir --no-binary :all: pystan
RUN pip3 install --compile --no-cache-dir fbprophet

## Copy entrypoint script, gpg key for backups and Odoo configuration file
COPY ./my_gpg_pubkey ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN set -x; \
    chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons /mnt/3rdparty-addons \
        /var/lib/odoo \
    && chown -R odoo:odoo /mnt/extra-addons /var/lib/odoo \
    && chmod +x /entrypoint.sh \
    && gosu odoo gpg --import /my_gpg_pubkey \
    && rm /my_gpg_pubkey

VOLUME ["/var/lib/odoo", "/mnt/extra-addons", "/mnt/3rdparty-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
# USER odoo

WORKDIR /odoo

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/entrypoint.sh", "odoo-bin"]
