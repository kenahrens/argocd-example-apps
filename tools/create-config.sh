#!/usr/bin/env bash

BASE_DIR="$(dirname ${BASH_SOURCE[0]})"

mkdir ~/.speedscale

cat ${BASE_DIR}/config-template.yaml | sed \
  -e "s/TENANT_ID/${TENANT_ID}/" \
  -e "s/TENANT_NAME/${TENANT_NAME}/" \
  -e "s/TENANT_BUCKET/${TENANT_BUCKET}/" \
  -e "s/TENANT_API_KEY/${TENANT_API_KEY}/" \
  -e "s/TENANT_STREAM/${TENANT_STREAM}/"
  > ~/.speedscale/config.yaml

sh -c "$(curl -sL https://downloads.speedscale.com/speedctl/install)"
