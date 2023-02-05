#!/bin/bash
# Bash script for sourcing either the current workspace environment or the default ROS one located in '/opt/ros/${ROS_DISTRO}'
# Author: Tobit Flatscher - github.com/2b-t (2021)
#
# Usage: - $ ./ros_source.sh
#          Defaults to "noetic"
#        - $ ./ros_source.sh <ros_distro>
#          ros_distro: Optional ROS distribution e.g. "melodic"


function main {
  local ROS_DISTRO=${1:-"noetic"}
  local CURRENT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
  local WORKSPACE_SOURCE_FILE="${CURRENT_PATH}/../devel/setup.bash"
  local DISTRO_SOURCE_FILE="/opt/ros/${ROS_DISTRO}/setup.bash"

  # Check if file local 'setup.bash' exists
  if [ -f "${WORKSPACE_SOURCE_FILE}" ]
    then
      source ${WORKSPACE_SOURCE_FILE}
      echo "Successfully sourced '${WORKSPACE_SOURCE_FILE}'."
  # Else check if distro 'setup.bash' exists
  elif [ -f "${DISTRO_SOURCE_FILE}" ]
    then
      source ${DISTRO_SOURCE_FILE}
      echo "Successfully sourced '${DISTRO_SOURCE_FILE}'."
  else
    echo "Error: Could not find 'setup.bash' file to source in '${WORKSPACE_SOURCE_FILE}' and '${DISTRO_SOURCE_FILE}'!"
  fi
}

main $@

