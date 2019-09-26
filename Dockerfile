FROM registry.pricepaper.com/odoo12-docker-extramodules:latest
LABEL maintainer="Ean J Price <ean@pricepaper.com>"

ENV ODOO_VERSION 12.0

RUN set -x; \
  cd / \
  && git clone -b $ODOO_VERSION --depth=1 https://github.com/PricePaper/odoo-custom \
  && rm -rf /odoo-custom/.git /odoo-custom/.github \
  && chown -R odoo:odoo /odoo-custom
