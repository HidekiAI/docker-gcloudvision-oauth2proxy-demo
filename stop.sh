#!/bin/bash

_DOCKER=$(which docker)
if [ x"${_DOCKER}" == x"" ]; then
	echo "# ERROR: Unable to locate docker"
	exit -1
fi
# assume NEWER version of Docker is installed, in which the legacy Python version of 'docker-compose' has been replaced with Go version of 'docker compose'
_DOCKER_COMPOSE="${_DOCKER} compose"
if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi

source build_image.env
# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'
echo "# FQ_DOMAIN_NAME: ${FQ_DOMAIN_NAME}"
echo "# MY_RUST_APP_PORT: ${MY_RUST_APP_PORT}"
set -o nounset      # Treat unset variables as an error

# stop images if running
${_DOCKER_COMPOSE} down --remove-orphans
${_DOCKER_COMPOSE} logs
${_DOCKER} stats --no-stream
