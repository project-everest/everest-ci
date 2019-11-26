#!/usr/bin/env bash

set -e

target=$1
out_file=$2
threads=$3
branchname=$4

# Add ssh identity
identity_added=false
if [[ -e .ssh/id_rsa ]] ; then
    eval $(ssh-agent)
    ssh-add .ssh/id_rsa
    identity_added=true
fi

echo $(date -u "+%Y-%m-%d %H:%M:%S")

result_file="result.txt"
success=false
{ { { { { { stdbuf -e0 -o0 ./build.sh "$@" && success=true ; } 3>&1 1>&2 2>&3 ; } | sed -u 's!^![STDERR]' ; } 3>&1 1>&2 2>&3 ; } | sed -u 's!^![STDOUT]' ; } 2>&1 ; } | tee $out_file
if $success ; then
    echo Success > $result_file
else
    echo Failure > $result_file
    exit 1
fi

echo "Build finished"

echo $(date -u "+%Y-%m-%d %H:%M:%S")

if $identity_added ; then
    eval $(ssh-agent)
    ssh-add -D
fi
