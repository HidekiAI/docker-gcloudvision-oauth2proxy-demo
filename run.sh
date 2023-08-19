#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi
_DOCKER=$(which docker)
_DOCKER_COMPOSE=$(which docker-compose)
if [ x"${_DOCKER}" == x"" ]; then
	echo "# ERROR: Unable to locate docker"
	exit -1
fi
if [ x"${_DOCKER_COMPOSE}" == x"" ]; then
    # assume NEWER version of Docker is installed, in which the legacy Python version of 'docker-compose' has been replaced with Go version of 'docker compose'
    _DOCKER_COMPOSE="${_DOCKER} compose"
fi

source build_image.env

# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'
echo "# FQ_DOMAIN_NAME: ${FQ_DOMAIN_NAME}"
echo "# MY_RUST_APP_PORT: ${MY_RUST_APP_PORT}"
set -o nounset      # Treat unset variables as an error

./stop.sh

# stop images if running
${_DOCKER_COMPOSE} down --remove-orphans

# first, build images
./build_image.sh ${FQ_DOMAIN_NAME} ${MY_RUST_APP_PORT}
sleep 5

# Show current configuration prior to running
${_DOCKER_COMPOSE} config

# now run
${_DOCKER_COMPOSE} up -d
# show which ports are exposed
${_DOCKER} ps

echo "Run '\$stats.sh' to check stats"
