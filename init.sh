#!/usr/bin/env bash

function not_yet_implemented() {
  echo "command: ${FUNCNAME[1]}"
  echo "is not not yet implemented"
  echo "but it's always great idea to contribute to this app ;)"
  return 1
}

function missing_action() {
  echo -e "\nMissing action for command mesos, available:\n"
  compgen -A function | grep "${FUNCNAME[1]}_" | sed -e "s/.*${FUNCNAME[1]}_/- /g"
  echo ''
  return 1
}

function init() {
  cli_tools="curl jq"

  for cli_cmd in $cli_tools; do
    type "$cli_cmd" > /dev/null
    if [ $? != 0 ]; then
      echo "$cli_cmd is missing or not available in defined PATH"
      echo "Use brew, macports, apt, yum or whatever package manager you use to install it."
      exit 1
    fi
  done
}

project_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
files_list=$(find "$project_path/functions" -type f)

for file in $files_list; do
  # shellcheck source=source/dotfiles.sh
  source "$file";
done

mesos() {
  cmd="mesos_$@"
  ${cmd/ /_}
  }
