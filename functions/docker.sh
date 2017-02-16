#!/usr/bin/env bash

DOCKER_REGISTRY='docker.vgnett.no'

# Build new image from Focerfile in current directory
#
# params: app_name version_no
#
# e.g. mesos build svp-foo 123456
#
function mesos_build() {
  echo "Building docker image"
  result=$(docker build -t $1 .)
  if [ $? == 0 ]; then
    image_id=$(echo $result | awk '/Successfully built/{print $NF}')
    container_image_id=$DOCKER_REGISTRY/$1:$2
    docker tag $image_id $container_image_id
    echo $container_image_id
  else
    echo "There was an error durring building image"
    echo $result
    false
  fi
}

# params: container_image_id
#
# e.g. mesos
#
function mesos_docker-push() {
  echo "Pushing image to $DOCKER_REGISTRY"
  docker push $1
}

# params: app_name
function mesos_deploy() {
  version_no=$(git rev-parse HEAD)
  container_image_id=$(mesos_build $1 $version_no)
echo $?
  #$(mesos_docker-push $container_image_id)
  #mesos_container $1 $container_image_id
  #echo $1
  #echo $container_image_id
}
