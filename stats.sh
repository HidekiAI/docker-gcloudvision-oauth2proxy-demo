#!/bin/bash

source build_image.env
# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'
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

#echo '#$ docker exec --interactive --user root --tty docker-gcloudvision-oauth2proxy_gateway_1 bash'
#echo '#$ docker exec --interactive --user root --tty docker-gcloudvision-oauth2proxy_www_1 bash'
#echo '#$ docker exec --interactive --user root --tty docker-gcloudvision-oauth2proxy_internal-developers_1 sh'
_CONTAINER_ID=$(docker stats --no-stream | grep "auth2" | grep -v "0B \/ 0B" | gawk '{ print $2}' )
if [ x"${_CONTAINER_ID}" != x"" ] ; then
	# show how to login to running container, since the target container is running alpine-linux, have to /bin/sh to it rather than /bin/bash
    for _C in $_CONTAINER_ID ; do
        echo "#$ docker exec --interactive --user root --tty ${_C} bash"
    done
else
	echo "# WARNING: Could not find a container 'oauth2-proxy' as a running container (via '$ docker stats --no-stream')"
fi

#sudo netstat -paven 2>&1 | grep "http\|https\|4180" 
ps auxf | grep "dockerd\|docker-proxy" | grep -v "grep\|dockerfile\|docker-gen" | grep --color=auto "dockerd\|docker-proxy"

# show which ports are exposed
docker ps

echo "# Use:"
echo '$ docker-compose logs --follow'