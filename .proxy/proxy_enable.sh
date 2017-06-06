#!/bin/bash
# Add proxy URL information below:
export PROXY_URL="<PROXY_URL>"
export ADD_NOPROXY_HOSTS="<ADD_NOPROXY_HOSTS>"
# No changes required should be required below:
export https_proxy=$PROXY_URL
export http_proxy=$PROXY_URL
export no_proxy=kubernetes.default,localhost,127.0.0.1,10.96.0.1,10.96.0.10,$ADD_NOPROXY_HOSTS
