#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function scoped_in_func () { "$@"; }


function v_do () {
  local DESCR=
  printf -v DESCR ' ‹%s›' "$@"
  echo "D:$DESCR:"
  "$@" || return $?$(echo "E:$DESCR: failed, rv=$?" >&2)
  echo "D:$DESCR: done."
}










return 0
