#!/bin/bash
# Arg1: Base/root domain name to be used for redirect-callbacks, vhosts.d, and ssl certs (i.e. use "mydomainname.tld" for "developers.mydomainname.tld")
# Arg2: Rust app port (i.e. "666")

function handle_error {
    set +x
    echo "# ERROR: An error occurred PID=$$ Command='$BASH_COMMAND' with RetCode=$? LINE=$LINENO" 1>&2
    exit -1
}
function handle_interrupt {
    set +x
    echo "Interrupt signal received. Exiting...  LastError RC=$? LINE=$LINENO"
    exit -2
}
function handle_term {
    set +x
    echo "Termination signal received. Performing cleanup...  LastError RC=$? LINE=$LINENO"
    exit -3
}
# Probabaly not needed but useful during debugging...
function handle_exit {
    set +x
    echo "Script exited. Performing cleanup... RC=$?"
    # don't exit with 0, since that will cause the trap to be called again
    exit $?
}
trap handle_term TERM
trap handle_error ERR
trap handle_interrupt INT
trap handle_exit EXIT   # this trap is not inherited by child processes, and also not really needed except for debugging

if [ x"$1" == x"" ] ; then
    echo "# ERROR: Missing domain name argument"
    echo "# Usage: $0 <domain_name.tld> <rust_app_port>"
    exit -1
fi

FQ_DOMAIN_NAME=$1
shift
if [ x"$1" == x"" ] ; then
    echo "# ERROR: Missing rust_app_port argument"
    echo "# Usage: $0 <domain_name.tld> <rust_app_port>"
    exit -1
fi
MY_RUST_APP_PORT=$1
shift
set -o nounset      # Treat unset variables as an error

export FQ_DOMAIN_NAME=${FQ_DOMAIN_NAME:-"your.domain.name.tld"}
export MY_RUST_APP_PORT=${MY_RUST_APP_PORT:-"666"}
export OAUTH2_PROXY_COOKIE_SECRET=""

_ENABLE_SECURITY_SCOUT=0

# NOTE: $which command will return RC=1 which can trigger $trap "EXIT"
trap - ERR
_DOCKER=$(which docker)
if [ x"${_DOCKER}" == x"" ]; then
	echo "# ERROR: Unable to locate docker"
	exit -1
fi
# assume NEWER version of Docker is installed, in which the legacy Python version of 'docker-compose' has been replaced with Go version of 'docker compose'
_DOCKER_COMPOSE="${_DOCKER} compose"
trap handle_term TERM
trap handle_error ERR
trap handle_interrupt INT
trap handle_exit EXIT   # this trap is not inherited by child processes, and also not really needed except for debugging
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
echo "export MY_RUST_APP_PORT=${MY_RUST_APP_PORT}" >> build_image.env

# for debug puproses, echo the cookie secret decoded
echo "# OAUTH2_PROXY_COOKIE_SECRET: $(echo ${OAUTH2_PROXY_COOKIE_SECRET} | tr -- '-_' '+/' | base64 -d | wc -c) bytes"   # if you care about something more than byte-count of 32, you can replace the 'wc -c' with 'hexdump -C'
echo "# FQ_DOMAIN_NAME: ${FQ_DOMAIN_NAME}"
echo "# MY_RUST_APP_PORT: ${MY_RUST_APP_PORT}"

pushd . 2>&1 > /dev/null
cd GCloudVision/
# Dockerfile version will build this as 'cargo build --release', no local target will be built
set -x
${_DOCKER} build --build-arg MY_RUST_APP_PORT=${MY_RUST_APP_PORT} --tag my-rust-app-image .
_ERR=$?
set +x
if [ ${_ERR} -ne 0  ]; then
    echo "# ERROR: ${_DOCKER} build failed with return code=${_ERR}"
    exit $_ERR
fi

popd
set -x
${_DOCKER_COMPOSE} build 
set +x
if [ ${_ERR} -ne 0  ]; then
    echo "# ERROR: ${_DOCKER_COMPOSE} build failed with return code=${_ERR}"
    exit $_ERR
fi
_ERR=$?

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

exit 0
