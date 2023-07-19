#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi

# stop images if running
docker-compose down

# first, build images
./build_image.sh

# now run
docker-compose up -d
