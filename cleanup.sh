#!/bin/bash

set -e
set -x

# Cleanup the Docker state
docker system prune --volumes --all --force

# Rebuild a base FStar image on master
now=$(date '+%Y%m%d%H%M%S')
tmpdir=/tmp/cleanup-$now
mkdir $tmpdir
pushd $tmpdir
git clone https://github.com/FStarLang/FStar
pushd FStar
GITHUB_SHA=$(git rev-parse HEAD)
popd
popd
ci_docker_image_tag=fstar:local-cleanup-run-$now
ci_docker_builder=builder_fstar_cleanup_$now
docker buildx create --name $ci_docker_builder --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=500000000
docker buildx build --builder $ci_docker_builder --pull --load -t $ci_docker_image_tag -f $tmpdir/FStar/.docker/standalone.Dockerfile --build-arg CI_BRANCH=master --build-arg CI_TARGET=uregressions $tmpdir/FStar
ci_docker_status=$(docker run $ci_docker_image_tag /bin/bash -c 'cat $FSTAR_HOME/status.txt' || echo false)
if $ci_docker_status ; then
    docker tag $ci_docker_image_tag fstar:local-branch-master
    docker tag $ci_docker_image_tag fstar:local-commit-$GITHUB_SHA
fi
docker buildx rm $ci_docker_builder
$ci_docker_status
rm -rf $tmpdir
