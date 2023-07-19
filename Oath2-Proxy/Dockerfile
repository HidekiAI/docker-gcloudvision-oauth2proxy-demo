# Use a minimal base image for the proxy
FROM alpine:latest

# Install required dependencies
RUN apk add --no-cache curl

# Download and install OAuth2 Proxy
RUN curl -L -o /usr/local/bin/oauth2_proxy https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v7.1.3/oauth2_proxy_linux_amd64

# Set the OAuth2 Proxy entrypoint
ENTRYPOINT ["/usr/local/bin/oauth2_proxy"]

