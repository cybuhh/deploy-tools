#!/usr/bin/env bash

# params: app_name
#
# e.g. mesos app-url app_name
function mesos_app-url {
  echo "http://marathon.int.vgnett.no/v2/apps/${1//\//%2F}/"
}

# find application
#
# params: app_name
#
# e.g. mesos find app_name
function mesos_app() {
  curl -s $(mesos_app-url $1) | jq '.app'
}

# find application instance tasks
#
# params: app_name
#
# e.g. mesos tasks app_name
function mesos_tasks() {
  curl -s $(mesos_app-url $1)/tasks | jq '.tasks'
}

# choose tasks from application instance
#
# params: app_name
#
# e.g. mesos tasks-choose app_name
#
function mesos_tasks-choose() {
  tasks_list=$(mesos_tasks $1)
  tasks_count=$(echo $tasks_list | jq 'length')
  read -p "Please enter instance number between 1 and $tasks_count:"$'\n' task_no
  if [ $task_no -gt $tasks_count ]; then
    echo "Instance #$task_no not exist"
    exit 1
  fi
  task=$(echo $tasks_list | jq ".[$task_no-1]")
  echo $task
}

# find application instance task
#
# params: app_name command
#
# e.g. mesos exec app_name bash
#
function mesos_exec() {
  task=$(mesos_tasks-choose $1)
  app_id=$(echo $task | jq '.appId'  | tr -d  '"')
  slave=$(echo $task | jq '.host'  | tr -d  '"')
  tash_id=$(echo $task | jq '.id'  | tr -d  '"')

  if [[ -n "$slave" && -n "$tash_id" ]]; then
    docker_cmd="container_name=\$(ps ax | grep docker | grep $app_id | sed -E 's/.+--name //g' | cut -d ' ' -f 1) && img_id=\$(docker ps -a --no-trunc |  grep \"\$container_name\" | cut -f 1 -d \" \") && docker exec -it \$img_id bash"
    echo $slave: $docker_cmd
    ssh -t $slave "$docker_cmd"
  else
    echo "Can't find docker container on slave ($slave)"
    exit 1
  fi
}

# scale app to give instances number
#
# params: app_name instances_number
#
# e.g. mesos scale app_name 3
#
function mesos_scale() {
  app=$(mesos_app $1)
  curl -X PUT -H 'Content-Type:application/json' -d "{\"instances\": $2}" $(mesos_app-url $1)
}

# suspend running application - scale to 0
#
# params: app_name instances_number
#
# e.g. mesos suspend app_name
#
function mesos_suspend() {
  $(mesos_scale 0)
}

# destroy application - remove completely from mesos
#
# params: app_name
#
# e.g. mesos destroy app_name
#
function mesos_destroy() {
  mesos__confirm "This operation will destroy permamently application $1. You can't undo once it's done." && \
  curl -s -X DELETE -H 'Content-Type:application/json' -d "{\"instances\": $2}" $(mesos_app-url $1)
}

# get/set docker container for given app name
#
# params: app_name [container_image_id]
#
# e.g. mesos container app_name
# e.g. mesos container app_name foo-bar
#
function mesos_container() {
  app=$(mesos_app $1)
  if [ $# -gt 1 ]; then
    query=curl $(mesos_app-url $1) | jq ".app | {container} | .container.docker.image |= \"$2\""
    curl -s -X PUT -H 'Content-Type:application/json' -d "$query" $(mesos_app-url $1)
  else
    curl -s $(mesos_app-url $1) | jq '.app.container.docker.image'
  fi
}