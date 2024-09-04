#!/bin/bash

set -e
set -x

# Cleanup the Docker state
docker system prune --volumes --all --force
