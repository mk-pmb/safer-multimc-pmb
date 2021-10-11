#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_cli () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SMMC_BASEDIR="$(readlink -m -- "$BASH_SOURCE"/..)"
  local -A CFG=()
  [ -n "$1" ] || return 3$(
    echo "E: No task given as first CLI argument. Try 'help'." >&2)
  CFG[task]="$1"; shift

  local LOAD_LIB=
  for LOAD_LIB in \
    "$SMMC_BASEDIR"/src/bash-funcs/*.sh \
    "$SMMC_BASEDIR"/src/tasks/"${CFG[task]}".sh \
  ; do
    [ -f "$LOAD_LIB" ] || continue
    source -- "$LOAD_LIB" --lib || return $?
  done
  unset LOAD_LIB

  smmc_load_all_config || return $?
  smmc_task_"${CFG[task]}" "$@" || return $?
}










smmc_cli "$@"; exit $?
