#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function mods_cmp () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")" # busybox
  # cd -- "$SELFPATH" || return $?

  local -A CFG=(
    [mcdir:ref]="$PWD"
    [mcdir:cmp]="$1"
    [mods_subdir]='.minecraft/mods'
    )
  local -A MEM=()
  autofix_mcdir ref || return $?
  scan_mods ref || return $?

  if [ -z "${CFG[mcdir:cmp]}" ]; then
    echo "${MEM[modvers:ref]}"
    return 0
  fi

  autofix_mcdir cmp || return $?
  scan_mods cmp || return $?
  cmp_mod_list || return $?
}


function autofix_mcdir () {
  local P="${CFG[mcdir:$1]}"
  P="${P%/}"
  P="${P%/mods}"
  P="${P%/dotmc}"
  P="${P%/.minecraft}"
  local S="${CFG[mods_subdir]}"
  local M="$P/$S"
  [ -d "$M" ] || return 3$(
    echo "E: sub path $S is not a directory in $1 path '$P'" >&2)
  CFG["mcdir:$1"]="$P"
}


function scan_mods () {
  local SIDE="$1"
  local MODS=()
  readarray -t MODS < <(list_mods "$SIDE")
  local ITEM= VER=
  for ITEM in "${MODS[@]}"; do
    VER="${ITEM#*$'\t'}"
    ITEM="${ITEM%%$'\t'*}"
    MEM["$SIDE:ver:$ITEM"]="$VER"
    MEM[all_names]+="$ITEM"$'\n'
  done
  MEM[all_names]="$(<<<"${MEM[all_names]}" grep -Pe '\S' \
    | sort --version-sort --unique)"
}


function list_mods () {
  local SIDE="$1"
  local MDIR="${CFG[mcdir:$SIDE]}/${CFG[mods_subdir]}"
  MDIR="$MDIR" sh -c 'cd -- "$MDIR" && ls -1' | sed -nrf <(echo '
    s~^0(.*)\.jar-X$~\1 <disabled>~
    /\.jar$|</!b
    s~\.jar$~~
    s~[0-9]+\.[0-9]+~\t&~
    s~(v)\t~\t\1~
    s~((\-|fabric|mod|mc))+\t~\t\1~
    s!\t\-!\t!
    p
    ') | sort --version-sort
  # unzip -p -- "$J" pack.mcmeta | tr -d '\n' | perl -e 'use JSON; my $p = (decode_json <>)->{"pack"}; print($p->{"description"}, "\n");'
}


function cmp_mod_list () {
  local ALL_NAMES=()
  readarray -t ALL_NAMES <<<"${MEM[all_names]}"
  local ITEM= REF_VER= CMP_VER=
  local SAMES=()
  echo "--- ${CFG[mcdir:ref]}"
  echo "+++ ${CFG[mcdir:cmp]}"
  echo
  for ITEM in "${ALL_NAMES[@]}"; do
    REF_VER="${MEM[ref:ver:$ITEM]}"
    CMP_VER="${MEM[cmp:ver:$ITEM]}"
    if [ "$REF_VER" == "$CMP_VER" ]; then
      SAMES+=( "$ITEM" )
    else
      echo " $ITEM"
      [ -z "$REF_VER" ] || echo "-    $REF_VER"
      [ -z "$CMP_VER" ] || echo "+    $CMP_VER"
      echo
    fi
  done
  printf -- ' %s\n' "${SAMES[@]}"
}










mods_cmp "$@"; exit $?
