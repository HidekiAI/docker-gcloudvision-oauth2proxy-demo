#!/bin/bash

docker image ls

# Note: 'docker scount' only exists on Windows?
if [ x"$1" != x"" ] ; then
    docker scout quickview
    sleep 5

    docker scout cves my-rust-app-image 
    sleep 5

    docker scout recommendations my-rust-app-image
fi
sleep 5

# Show current configuration prior to running
docker-compose config
date

docker-compose logs
docker-compose images
docker-compose top
docker stats --no-stream

_CONTAINER_ID=$(docker stats --no-stream | grep "auth2" | gawk '{ print $1}' )
if [ x"${_CONTAINER_ID}" != x"" ] ; then
	# show how to login to running container, since the target container is running alpine-linux, have to /bin/sh to it rather than /bin/bash
    for _C in $_CONTAINER_ID ; do
        echo "# docker exec --interactive --tty ${_C} bash"
    done
else
	echo "# WARNING: Could not find a container 'oauth2-proxy' as a running container (via '$ docker stats --no-stream')"
fi

sudo netstat -paven 2>&1 | grep "http\|https\|4180" 
