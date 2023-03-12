#!/bin/sh
function create_if_not_exists() {
  if [ -z "$1" ]
  then
    echo "No argument provided for dir check"
    exit 1
  fi
  if [ ! -d "$1" ]
  then
    mkdir -p "$1"
  fi
}
export XDG_DATA_HOME="$HOME/.data"
create_if_not_exists "$XDG_DATA_HOME"
export XDG_CONFIG_HOME="$HOME/.config"
create_if_not_exists "$XDG_CONFIG_HOME"
export XDG_STATE_HOME="$HOME/.state"
create_if_not_exists "$XDG_STATE_HOME"
export XDG_CACHE_HOME="$HOME/.cache"
create_if_not_exists "$XDG_CACHE_HOME"
export USER_CODE_DIR="$HOME/code"
