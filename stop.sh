#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi
source build_image.env
# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'

# stop images if running
docker-compose down --remove-orphans
docker-compose logs
docker stats --no-stream
