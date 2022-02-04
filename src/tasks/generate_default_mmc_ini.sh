#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_task_generate_default_mmc_ini () {
  local KEY=
  echo '; -*- coding: utf-8, tab-width: 2 -*-'
  echo
  for KEY in "${!CFG[@]}"; do case "$KEY" in
    mmcdflt:* ) echo "${KEY#*:}=${CFG[$KEY]}";;
  esac; done | LANG=C sort --version-sort
}












return 0
