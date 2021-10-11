#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_task_help () {
  local TOPIC="$1"; shift
  help_"${TOPIC:-list_known_tasks}" "$@" || return $?
}



function help_list_known_tasks () {
  local FUNCS=
  local ITEM=
  for ITEM in "$SMMC_BASEDIR"/src/tasks/*.sh; do
    FUNCS+=$', '"$(basename -- "$ITEM" .sh)"
  done
  FUNCS="${FUNCS#* }"
  echo "H: Known tasks: $FUNCS"
}










return 0
