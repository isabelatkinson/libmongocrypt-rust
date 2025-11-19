#!/bin/bash

set -o errexit
set +x

if [[ -z "$CRATE" ]]; then
    echo >&2 "CRATE is required"
    exit 1
fi
if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo >&2 "AWS_ACCESS_KEY_ID is required"
    exit 1
fi
if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo >&2 "AWS_SECRET_ACCESS_KEY is required"
    exit 1
fi
if [[ -z "$GARASIGN_USERNAME" ]]; then
    echo >&2 "GARASIGN_USERNAME is required"
    exit 1
fi
if [[ -z "$GARASIGN_PASSWORD" ]]; then
    echo >&2 "GARASIGN_PASSWORD is required"
    exit 1
fi

CRATE_VERSION=$(cargo metadata --format-version=1 --no-deps | jq --raw-output '.packages[0].version')

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 901841024863.dkr.ecr.us-east-1.amazonaws.com

echo "GRS_CONFIG_USER1_USERNAME=${GARASIGN_USERNAME}" >> "signing-envfile"
echo "GRS_CONFIG_USER1_PASSWORD=${GARASIGN_PASSWORD}" >> "signing-envfile"

docker run \
  --env-file=signing-envfile \
  --rm \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  901841024863.dkr.ecr.us-east-1.amazonaws.com/release-infrastructure/garasign-gpg \
  /bin/bash -c "gpgloader && gpg --yes -v --armor -o ${CRATE}-${CRATE_VERSION}.sig --detach-sign target/package/${CRATE}-${CRATE_VERSION}.crate"

rm signing-envfile
