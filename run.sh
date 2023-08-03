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

echo "Run '$stats.sh' to check stats"
