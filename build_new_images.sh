#!/bin/bash

PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
export PATH

BUILD_DATE=`date +%Y%m%d%H%M`
BUILD_DIR=$PWD
REGISTRY="local"
GITLOGIN="gitpassword=01e7750beb8b30e2a8ff7d773a29a9a2e5540c87"

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
