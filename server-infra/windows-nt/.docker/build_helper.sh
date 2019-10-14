#!/usr/bin/env bash

set -e


# Add ssh identity
identity_added=false
if [[ -e .ssh/id_rsa ]] ; then
    eval $(ssh-agent)
    ssh-add .ssh/id_rsa
    identity_added=true
fi

echo $(date -u "+%Y-%m-%d %H:%M:%S")

./build.sh

echo "Build finished"

echo $(date -u "+%Y-%m-%d %H:%M:%S")

if $identity_added ; then
    eval $(ssh-agent)
    ssh-add -D
fi
