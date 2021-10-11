#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_load_all_config () {
  local LIST=(
    "$SMMC_BASEDIR"/src/cfg/*.rc
    )
  local ITEM=
  for ITEM in "${LIST[@]}"; do
    [ -f "$ITEM" ] || continue
    scoped_in_func source -- "$ITEM" || return $?$(
      echo "E: Failed (rv=$?) to load config file '$ITEM'" >&2)
  done
}










return 0
