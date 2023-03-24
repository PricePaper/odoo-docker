#!/usr/bin/bash
#

if [-z $1];then
    echo "usage: $0 arch (amd64/arm64...)"
    exit 1
fi

set -x

BUILD_DATE=`date +%Y%m%d%H%M`
REGISTRY="registry.digitalocean.com/pricepaper"
BASE="odoo15-base"
ARCH=$1
IMAGE="${REGISTRY}/${BASE}:${ARCH}-${BUILD_DATE}"
IMAGE_LATEST="${REGISTRY}/${BASE}:${ARCH}-latest"


container=$(buildah from debian:bullseye-slim)

buildah config --author "Ean J Price <ean@pricepaper.com>" \
      -e LANG="en_US.utf8" \
      -e ODOO_VERSION=15.0 \
      -e BUILD_DATE=${BUILD_DATE} \
      -l build-date=${BUILD_DATE} \
      -l stage=${BASE} \
	 $container

buildah run $container bash -x <<EOF
	apt-get update \
	&& apt-get install -y locales \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
              ca-certificates \
              curl \
              cython3 \
              dumb-init \
              fonts-font-awesome \
              fonts-inconsolata \
              fonts-noto-cjk \
              fonts-roboto-unhinted \
              git \
              gnupg \
              gosu \
              gsfonts \
              libfreetype6-dev \
              libjpeg-dev \
              libjs-underscore \
              libldap2-dev \
              libpq-dev \
              libsasl2-dev \
              libssl-dev \
              libtiff-dev \
              libxml2-dev \
              libxslt-dev \
              libxslt1-dev \
              lsb-base \
              node-less \
              npm \
              python3-aiohttp \
              python3-asn1crypto \
              python3-boto \
              python3-boto3 \
              python3-cffi \
              python3-chardet \
              python3-convertdate \
              python3-cryptography \
              python3-decorator \
              python3-dev \
              python3-docutils \
              python3-ephem \
              python3-freezegun \
              python3-gevent \
              python3-googleapi \
              python3-greenlet \
              python3-jinja2 \
              python3-idna \
              python3-ldap \
              python3-libsass \
              python3-lxml \
              python3-markupsafe \
              python3-matplotlib \
              python3-mock \
              python3-num2words \
              python3-odf \
              python3-ofxparse \
              python3-openssl \
              python3-pandas \
              python3-passlib \
              python3-pdfminer \
              python3-phonenumbers \
              python3-pip \
              python3-plotly \
              python3-polib \
              python3-psutil \
              python3-pyasn1-modules \
              python3-pycparser \
              python3-pydot \
              python3-pyldap \
              python3-pymeeus \
              python3-pypdf2 \
              python3-qrcode \
              python3-redis \
              python3-renderpm \
              python3-reportlab \
              python3-requests \
              python3-serial \
              python3-setuptools \
              python3-setuptools-git \
              python3-slugify \
              python3-stdnum \
              python3-tqdm \
              python3-tz \
              python3-vobject \
              python3-u2flib-server \
              python3-usb \
              python3-watchdog \
              python3-werkzeug \
              python3-wheel \
              python3-xlrd \
              python3-xlsxwriter \
              python3-xlwt \
              python3-zeep \
              python3-zope.event \
              python3-zope.interface \
              unzip \
              vim-tiny \
              xz-utils \
              zip \
              zlib1g-dev \
        && useradd -c "Odoo User" -u 23789 -d /odoo -m odoo \
        && echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
        && curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
            apt-key add - \
        && apt-get update \
        && apt-get install -y postgresql-client-14 python3-psycopg2 \
        && curl -o /tmp/wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
        && apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/* /tmp/wkhtmltox.deb \
        && pip3 config set global.no-cache-dir false \
        && pip3 install 'Babel==2.9.1' 'Pillow==9.0.1' 'ebaysdk==2.1.5' PyDrive \
        && npm install -g rtlcss \
        && mkdir /addons /etc/odoo /var/lib/odoo \
        && chown odoo:odoo /addons /var/lib/odoo 
EOF
buildah copy --chmod 640 --chown root:odoo $container ./odoo.conf /etc/odoo/
buildah copy --chmod 755 $container ./entrypoint.sh /
buildah copy --chmod 755 $container wait-for-psql.py /usr/local/bin/wait-for-psql.py

buildah config \
	--env ODOO_RC=/etc/odoo/odoo.conf \
	--env BUILD_DATE=${BUILD_DATE} \
	--workingdir /odoo \
	-p 8069 -p 8071 -v /var/lib/odoo \
	--entrypoint '["/usr/bin/dumb-init", "--"]' \
	--cmd '["/entrypoint.sh", "odoo-bin"]' \
	$container

buildah commit $container ${IMAGE}
buildah rm ${IMAGE}
buildah tag ${IMAGE} ${IMAGE_LATEST}

buildah push ${IMAGE}
buildah push ${IMAGE_LATEST}
