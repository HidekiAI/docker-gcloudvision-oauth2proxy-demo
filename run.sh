#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi

# stop images if running
docker-compose down --remove-orphans

# first, build images
./build_image.sh

# Show current configuration prior to running
docker-compose config

# now run
docker-compose up -d
docker-compose images ls

# wait a bit before dumping log
sleep 5
date
docker-compose logs
