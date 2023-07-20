#!/bin/bash
_DOCKER=$(which docker)
if [ x"${_DOCKER}" == x"" ]; then
	echo "# ERROR: Unable to locate docker"
	exit -1
fi

# According to https://oauth2-proxy.github.io/oauth2-proxy/docs/, there is already a docker image, so we'll use the official image
docker pull quay.io/oauth2-proxy/oauth2-proxy:latest

pushd . 2>&1 > /dev/null
cd GCloudVision/
docker build -t my-rust-app-image .
popd

docker image ls
