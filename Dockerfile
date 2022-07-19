FROM registry.digitalocean.com/pricepaper/odoo15-extramodules:latest
LABEL maintainer="Ean J Price <ean@pricepaper.com>"

ENV ODOO_GIT_VERSION 15-migration

RUN set -x; \
  cd / \
  && apt update \
  && apt upgrade -y \
  && rm -rf /var/lib/apt/lists/* \
  && git clone -b $ODOO_GIT_VERSION --depth=1 https://github.com/PricePaper/odoo-custom-v15.git \
	/odoo-custom \
  && rm -rf /odoo-custom/.git /odoo-custom/.github \
  && chown -R odoo:odoo /odoo-custom
