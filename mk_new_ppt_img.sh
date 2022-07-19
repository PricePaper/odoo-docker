#!/bin/bash

PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
export PATH

BUILD_DATE=`date +%Y%m%d%H%M`
BUILD_DIR="/home/ejprice/docker/odoo15"
REGISTRY="registry.digitalocean.com/pricepaper"

# Names of the images we need to build
declare -a IMGNAMES=("ppt")

# Change to build dir and build new image
cd $BUILD_DIR

# build each image in turn and push
for img in "${IMGNAMES[@]}"
do
  # Build image
  docker build . -t ${REGISTRY}/odoo15-${img}:${BUILD_DATE} \
    -f Dockerfile.${img} --pull --no-cache
  [ $? != 0 ] && exit 1
  docker tag ${REGISTRY}/odoo15-${img}:${BUILD_DATE} \
	${REGISTRY}/odoo15-${img}:latest

  # Push to repository
  docker push ${REGISTRY}/odoo15-${img}:${BUILD_DATE}
  docker push ${REGISTRY}/odoo15-${img}:latest
done
echo ${BUILD_DATE} > ${BUILD_DIR}/.buildinfo/current
kubectl set image deployment/odoo-app odoo=registry.digitalocean.com/pricepaper/odoo15-ppt:${BUILD_DATE}
kubectl rollout status deployment odoo-app
