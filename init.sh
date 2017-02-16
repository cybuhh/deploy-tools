#!/usr/bin/env bash

# display information that current function is missing action paramenter
#
function mesos__not_yet_implemented() {
  echo "command: ${FUNCNAME[1]}"
  echo "is not not yet implemented"
  echo "but it's always great idea to contribute to this app ;)"
  return 1
}

# display information that current function is missing action paramenter
#
function mesos__missing_action() {
  echo -e "\nMissing action for command mesos, available:\n"
  compgen -A function | grep "${FUNCNAME[1]}_" | sed -e "s/.*${FUNCNAME[1]}_/- /g"
  echo ''
  return 1
}

# Display message and ask for confirmation
#
# params: information
function mesos__confirm() {
  read -r -p "$1"$'\nAre you sure? [y/N] ' response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
    ;;
    *)
      false
    ;;
  esac
}

function mesos__init() {
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

mesos__init

mesos() {
  cmd="mesos_$@"
  $cmd
}

mesos deploy svp/sifter stage
