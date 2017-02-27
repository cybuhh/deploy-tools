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
  echo $(curl -s $(mesos_app-url $1) | jq '.app')
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
  case "$tasks_count" in
    0)
      echo 'No tasks running for given app'
      return
      ;;
    1)
      task=$(echo $tasks_list | jq ".[0]")
      echo $task
      ;;
    *)
      read -p "Please enter instance number between 1 and $tasks_count:"$'\n' task_no
      if [ $task_no -gt $tasks_count ]; then
        echo "Instance #$task_no not exist"
        return
      fi
      task=$(echo $tasks_list | jq ".[$task_no-1]")
      echo $task
  esac
}

# find application instance task
#
# params: app_name command
#
# e.g. mesos exec app_name bash
#
function mesos_exec() {
  task=$(mesos_tasks-choose $1)

  if [[ "$task" == {*} ]]; then
    app_id=$(echo $task | jq '.appId'  | tr -d  '"')
    slave=$(echo $task | jq '.host'  | tr -d  '"')
    task_id=$(echo $task | jq '.id'  | tr -d  '"')
  fi

  if [[ -n "$app_id" &&  -n "$slave" && -n "$task_id" ]]; then
    docker_cmd="container_name=\$(ps ax | grep docker | grep $app_id | sed -E 's/.+--name //g' | cut -d ' ' -f 1) && img_id=\$(docker ps -a --no-trunc |  grep \"\$container_name\" | cut -f 1 -d \" \") && docker exec -it \$img_id bash"
    echo $slave: $docker_cmd
    ssh -t $slave "$docker_cmd"
  else
    echo "Can't find docker container on slave"
    return 1
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
  curl -X PUT -H 'Content-Type:application/json' -d "{\"instances\": $2}" $(mesos_app-url $1)?force=true
}

# suspend running application - scale to 0
#
# params: app_name instances_number
#
# e.g. mesos suspend app_name
#
function mesos_suspend() {
  mesos_scale $1 0
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
    app_url=$(mesos_app-url $1)
    query=$(curl $app_url | jq ".app | {container} | .container.docker.image |= \"$2\"")
    curl -s -X PUT -H 'Content-Type:application/json' -d "$query" $(mesos_app-url $1)
  else
    curl -s $(mesos_app-url $1) | jq '.app.container.docker.image'
  fi
}
