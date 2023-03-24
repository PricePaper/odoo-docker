#!/usr/bin/env bash

set -x

container=$(buildah from --arch amd64 registry.digitalocean.com/pricepaper/odoo15-core:latest)

BUILD_DATE=`date +%Y%m%d%H%M`
REGISTRY="registry.digitalocean.com/pricepaper"
BASE="odoo15-ppt"
IMAGE="${REGISTRY}/${BASE}:${BUILD_DATE}"
ODOO_CUSTOM_GIT_BRANCH=15-migration

buildah config --author "Ean J Price <ean@pricepaper.com>" \
		-e BUILD_DATE=${BUILD_DATE} \
		-e ODOO_CUSTOM_GIT_BRANCH=${ODOO_CUSTOM_GIT_BRANCH} \
		-l build-date=${BUILD_DATE} \
		$container


buildah run $container bash -x <<EOF
	cd / \
  	&& apt update \
  	&& apt upgrade -y \
  	&& rm -rf /var/lib/apt/lists/* \
  	&& git clone -b $ODOO_CUSTOM_GIT_BRANCH --depth=1 https://github.com/PricePaper/odoo-custom-v15.git \
					/odoo-custom \
  	&& rm -rf /odoo-custom/.git /odoo-custom/.github \
  	&& chown -R odoo:odoo /odoo-custom
EOF

buildah commit $container ${IMAGE}
buildah tag ${IMAGE} ${REGISTRY}/${BASE}:latest

buildah push ${IMAGE}
buildah push ${REGISTRY}/${BASE}:latest

echo ${BUILD_DATE} > .buildinfo/current

kubectl set image deployment/odoo-longpolling odoo-longpolling=${IMAGE}
kubectl set image deployment/odoo-app odoo=${IMAGE}
kubectl rollout status deployment odoo-app
