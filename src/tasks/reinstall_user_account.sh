#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_task_reinstall_user_account () {
  local U_NAME="${CFG[sbx_user_name]}"
  local G_NAME="${CFG[sbx_user_group]}"
  local U_HOME="${CFG[sbx_home_dir]}"

  local UN_MAXLEN=14
  # ^-- In case you really want to push your luck:
  # `man useradd` says Ubuntu can handle up to 32 chars.
  [ "${#U_NAME}" -le "$UN_MAXLEN" ] || return 4$(
    echo "E: Username too long: '$U_NAME', length ${#U_NAME} > $UN_MAXLEN" >&2)

  if cut -d : -sf 1 -- /etc/passwd | grep -qxFe "$U_NAME"; then
    echo "D: Remove old user account '$U_NAME':"
    sudo userdel "$U_NAME" || return $?
  fi

  local U_ADD=(
    sudo
    useradd
    --comment "Sandbox account for ${CFG[sbx_user_descr]}"
    --home-dir "$U_HOME"
    --no-create-home
    --shell /bin/false
    )

  if [ "$G_NAME" == "$U_NAME" ]; then
    U_ADD+=( --user-group )
  else
    U_ADD+=( --gid "$G_NAME" )
  fi

  U_ADD+=( "$U_NAME" )
  echo -n "D: Create new user account '$U_NAME':"
  printf ' ‹%s›' "${U_ADD[@]}"
  echo
  "${U_ADD[@]}" || return $?

  echo "D: Create home directory:"
  sudo mkdir --parents -- "$U_HOME" || return $?
  echo "D: Adjust home directory ownership:"
  sudo chown "$U_NAME:$G_NAME" --recursive -- "$U_HOME" || return $?
  echo "D: Done."
}












return 0
