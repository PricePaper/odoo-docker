#!/usr/bin/bash

set -x

BUILD_DATE=`date +%Y%m%d%H%M`
REGISTRY="registry.digitalocean.com/pricepaper"
BASE="odoo15-core"
ARCH=$1
IMAGE="${REGISTRY}/${BASE}:${ARCH}-${BUILD_DATE}"
IMAGE_LATEST="${REGISTRY}/${BASE}:${ARCH}-latest"

container=$(buildah from --arch ${ARCH} registry.digitalocean.com/pricepaper/odoo15-base:${ARCH}-latest)

buildah config --author "Ean J Price <ean@pricepaper.com>" \
        -e BUILD_DATE=${BUILD_DATE} \
        -l build-date=${BUILD_DATE} \
        -l stage=${BASE} \
        $container

buildah copy --chown=odoo:odoo $container sources/addons /addons/
buildah copy --chown=odoo:odoo $container sources/odoo /odoo/
buildah copy --chown=odoo:odoo $container sources/enterprise /enterprise/

buildah run $container bash -x <<EOF
	pip3 install --no-cache-dir -e /odoo \
    && pip3 install --no-cache-dir --upgrade --upgrade-strategy only-if-needed \
    --extra-index-url=https://wheelhouse.odoo-community.org/oca-simple \
    'odoo-addon-queue-job<16.0' \
    'odoo-addon-partner-firstname<16.0' \
    'odoo-addon-partner-contact-personal-information-page<16.0' \
    'odoo-addon-partner-phone-extension<16.0' \
    'odoo-addon-base-location-geonames-import<16.0' \
    'odoo-addon-product-form-purchase-link<16.0' \
    'odoo-addon-auditlog<16.0' \
    'odoo-addon-stock-location-lockdown<16.0' \
    'odoo-addon-stock-available-unreserved<16.0' \
    'odoo-addon-stock-no-negative<16.0' \
    'odoo-addon-purchase-deposit<16.0' \
    'odoo-addon-partner-time-to-pay<16.0' \
    'odoo-addon-purchase-reception-notify<16.0' \
    && pip3 install --upgrade --upgrade-strategy only-if-needed 'prophet<1.2' \
    && pip3 install --upgrade --upgrade-strategy only-if-needed click-odoo
EOF

buildah commit $container ${IMAGE}
buildah tag ${IMAGE} ${IMAGE_LATEST}

buildah push ${IMAGE}
buildah push ${IMAGE_LATEST}
