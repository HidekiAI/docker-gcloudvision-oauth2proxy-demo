# Use a minimal base image for the proxy
#FROM debian:buster-slim
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache curl
#RUN apt-get update && apt-get install -y curl

# Set the version to the latest release
# Example: curl -L https://github.com/oauth2-proxy/oauth2-proxy/releases/download/${VERSION}/oauth2-proxy-${VERSION}.$(go env GOOS)-$(go env GOARCH).tar.gz | tar xz && \
# NOTE: Because we already know we're on alpine Linux, we will NOT use $(go env GOOS) and $(go env GOARCH) and assume it's target platform is amd64-linux
RUN VERSION=$(curl -s https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    curl -L https://github.com/oauth2-proxy/oauth2-proxy/releases/download/${VERSION}/oauth2-proxy-${VERSION}.linux-amd64.tar.gz | tar xz && \
    mv /oauth2-proxy-${VERSION}.linux-amd64/oauth2-proxy /usr/local/bin/
    #mv /oauth2-proxy-${VERSION}.$(go env GOOS)-$(go env GOARCH)/oauth2-proxy /usr/local/bin/

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/oauth2-proxy"]

