#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi
source build_image.env
# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'
echo "# FQ_DOMAIN_NAME=${FQ_DOMAIN_NAME}"

./stop.sh

# stop images if running
docker-compose down --remove-orphans

# first, build images
./build_image.sh ${FQ_DOMAIN_NAME}
sleep 5

# Show current configuration prior to running
docker-compose config

# now run
docker-compose up -d

echo "Run '\$stats.sh' to check stats"
