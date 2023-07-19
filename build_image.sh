#!/bin/bash


pushd . 2>&1 > /dev/null
cd Oath2-Proxy/
docker build -t oauth2-proxy-image .
popd


pushd . 2>&1 > /dev/null
cd GCloudVision/
docker build -t my-rust-app-image .
popd
