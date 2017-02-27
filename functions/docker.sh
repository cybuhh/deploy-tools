#!/usr/bin/env bash

DOCKER_REGISTRY='docker.vgnett.no'

function mesos__build-version() {
  git rev-parse HEAD
}

# Build new image from Focerfile in current directory
#
# params: app_name version_no
#
# e.g. mesos build svp-foo 123456
#
function mesos_build() {
  result=$(docker build -t $1 .)
  if [ $? == 0 ]; then
    image_id=$(echo $result | awk '/Successfully built/{print $NF}')
    container_image_id=$DOCKER_REGISTRY/$1:${2:-$(mesos__build-version)}
    docker tag $image_id $container_image_id
    echo $container_image_id
  else
    false
  fi
}

# params: container_image_id
#
# e.g. mesos
#
function mesos_push() {
  echo "Pushing image to $DOCKER_REGISTRY"
  docker push $1
}

# params: app_name env_name
function mesos_deploy() {
  version_no=$(mesos__build-version)
  container_image_id=$(mesos_build $1 $version_no)
  if [ $# -lt 2 ]; then
    mesos__confirm "No application name provided, $1 will be used"
    app_name=$1
  else
    app_name=$2
  fi

  mesos_push $container_image_id
  mesos_container $app_name $container_image_id
}
