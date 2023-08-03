#!/bin/bash

if ! [ -e docker-compose.yml ] ; then
	echo "# ERROR: Unable to locate 'docker-compose.yml' file in the current directory '$(pwd)'"
	exit -1
fi

# stop images if running
docker-compose down --remove-orphans
docker-compose config
docker-compose logs
docker-compose ls --all
docker-compose top
docker stats --no-stream
