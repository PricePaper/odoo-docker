#!/bin/bash

PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
export PATH

BUILD_DATE=`date +%Y%m%d%H%M`
BUILD_DIR=$PWD
REGISTRY="local"
GITLOGIN="gitpassword=9409e9741e7e972e35e8ce518017686ce8fdacc7"

# Names of the images we need to build
declare -a IMGNAMES=("base" "extramodules" "ppt")

# Change to build dir and build new image
cd $BUILD_DIR

# build each image in turn and push
for img in "${IMGNAMES[@]}"
do
  # Build image
  docker build . -t ${REGISTRY}/odoo12-docker-${img}:${BUILD_DATE} \
    -f Dockerfile.${img} --build-arg ${GITLOGIN} --pull --no-cache
  [ $? != 0 ] && exit 1
  docker tag ${REGISTRY}/odoo12-docker-${img}:${BUILD_DATE} \
	${REGISTRY}/odoo12-docker-${img}:latest
done
