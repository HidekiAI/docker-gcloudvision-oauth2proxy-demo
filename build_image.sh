#!/bin/bash
# Arg1: Domain name to be used for redirect-callbacks, vhosts.d, and ssl certs (i.e. "mydomainname.tld")
if [ x"$1" == x"" ] ; then
    echo "# ERROR: Missing domain name argument"
    echo "# Usage: $0 <domain_name.tld>"
    exit -1
fi
set -o nounset      # Treat unset variables as an error

FQ_DOMAIN_NAME=$1
export FQ_DOMAIN_NAME=${FQ_DOMAIN_NAME:-"your.domain.name.tld"}

_ENABLE_SECURITY_SCOUT=0

_DOCKER=$(which docker)
_DOCKER_COMPOSE=$(which docker-compose)
if [ x"${_DOCKER}" == x"" ]; then
	echo "# ERROR: Unable to locate docker"
	exit -1
fi
if [ x"${_DOCKER_COMPOSE}" == x"" ]; then
    echo "# ERROR: Unable to locate docker-compose"
    exit -1
fi
./stop.sh

# NOTE: if not using docker-compose, then we need to build the images manually
# According to https://oauth2-proxy.github.io/oauth2-proxy/docs/, there is already a ${_DOCKER} image, so we'll use the official image
#${_DOCKER} pull quay.io/oauth2-proxy/oauth2-proxy:latest
#${_DOCKER} pull jwilder/nginx-proxy:latest

# Generate new cookie secret for every rebuilds
#$ dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo
# NOTE: Have to strip carriage returns and newlines prior to base64 encoding, or else the cookie secret will be invalid due to being +1 (/n) or +2 (/r/n) bytes more than expected!
#_COOKIE=$( dd if=/dev/urandom bs=32 count=1 2>/dev/null )
#_BASE64_COOKIE=$(echo $_COOKIE |  tr -d -- '\n' | tr -d -- '\r' | base64)
# NOTE: the `dd if=/dev/urandom bs=32 count=1 2>/dev/null` command above is somehow generating 44 bytes instead of 32 bytes, so we'll use openssl instead
_BASE64_COOKIE=$(openssl rand -base64 32)
# replace '+' with '-' and '/' with '_' - no need to worry about whether original base64 string contains "-" or "_", since base64
# generates only "=", "+" and "/" characters (see https://en.wikipedia.org/wiki/Base64#Base64_table)
export OAUTH2_PROXY_COOKIE_SECRET="$(echo $_BASE64_COOKIE | tr -- '+/' '-_'  )"
if [ x"${OAUTH2_PROXY_COOKIE_SECRET}" == x"" ]; then
    echo "# ERROR: Unable to generate cookie secret"
    exit -1
fi
# not really a security issue to persist the cookie secret in the build_image.env file, since the cookie secret has to persist here, in oauth2-proxy.cfg, or in the bash script
# but the nice thing about build_image.env is that you can `$ source build_image.env` to be used as-is
echo "export OAUTH2_PROXY_COOKIE_SECRET=${OAUTH2_PROXY_COOKIE_SECRET}" > build_image.env
echo "export FQ_DOMAIN_NAME=${FQ_DOMAIN_NAME}" >> build_image.env
# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'

pushd . 2>&1 > /dev/null
cd GCloudVision/
# Dockerfile version will build this as 'cargo build --release', no local target will be built
${_DOCKER} build --tag my-rust-app-image .
popd
${_DOCKER_COMPOSE} build 

${_DOCKER} image ls

# Note: '${_DOCKER} scount' only exists on Windows?
if [ x"$_ENABLE_SECURITY_SCOUT" != x"" ] && [ ${_ENABLE_SECURITY_SCOUT} -ne 0 ] ; then
    # NOTE: ${_DOCKER} scout is currently in beta only, and also, it's going to most likely be a paid plugin
    # see '${_DOCKER} pull docker/scout-cli' for more info...
    ${_DOCKER} scout quickview
    sleep 5

    ${_DOCKER} scout cves my-rust-app-image 
    sleep 5

    ${_DOCKER} scout recommendations my-rust-app-image
fi
