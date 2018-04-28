# This script is responsible to prune all objects old than 24 hours.

# TODO - Script to clean up old images.
# $images = docker images --format '{{json .}}'
# docker container prune --filter "label!=keep"