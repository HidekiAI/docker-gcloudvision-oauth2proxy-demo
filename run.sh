#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi

./stop.sh

# stop images if running
docker-compose down --remove-orphans

# first, build images
./build_image.sh
sleep 5

# Show current configuration prior to running
docker-compose config

# now run
docker-compose up -d

# wait a bit before dumping log
sleep 5
date
docker-compose logs
docker-compose ls --all
docker-compose top
docker stats --no-stream

_CONTAINER_ID=$(docker stats --no-stream | grep "auth2" | gawk '{ print $1}' )
if [ x"${_CONTAINER_ID}" != x"" ] ; then
	# show how to login to running container, since the target container is running alpine-linux, have to /bin/sh to it rather than /bin/bash
	echo "# docker exec --interactive --tty ${_CONTAINER_ID} sh"
else
	echo "# WARNING: Could not find a container 'oauth2-proxy' as a running container (via '$ docker stats --no-stream')"
fi

