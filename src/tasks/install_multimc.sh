#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_task_install_multimc () {
  # The essential install strategy is based on
  #   https://github.com/MultiMC/MultiMC5/blob/29f304f0703612d56b26
  #   d111cf802e145ae5896f/launcher/package/ubuntu/multimc/opt/multimc/run.sh
  # but this is a new implementation from scratch,
  # with added safety measures and security checks.

  local MACHINE_ARCH="$(uname -m)"
  case "$MACHINE_ARCH" in
    x86_64 ) ;;
    * )
      echo "E: unsupported machine architecture: '$MACHINE_ARCH'" >&2
      return 3;;
  esac

  local DL_URL='
    https://web.archive.org/web/
    2021 10 09   08 49 08
    /https://files.multimc.org/downloads/mmc-stable-lin64.tar.gz
    '
  DL_URL="${DL_URL//[$'\n ']/}"
  local CACHE_DIR='download-cache'
  local SAVE_AS="$CACHE_DIR/$(basename -- "$DL_URL")"
  wget_dl "$DL_URL" "$SAVE_AS" || return $?
  verify_tarball "$SAVE_AS" trusted_tarballs.md || return $?
  unpack_tarball "$SAVE_AS" || return $?
}


function wget_dl () {
  local DL_URL="$1"; shift
  local SAVE_AS="$1"; shift
  echo -n "D: Download: $SAVE_AS "
  if [ -s "$SAVE_AS" ]; then
    echo "exists, skip."
    return 0
  fi
  local DL_DIR="$(dirname -- "$SAVE_AS")"
  mkdir --parents -- "$DL_DIR" || return $?
  local TMP_DL="$DL_DIR/tmp.$(date +%y%m%d-%H%M
    ).$$.$(basename -- "$SAVE_AS").part"
  local WGET_OPT=(
    --output-document="$TMP_DL"
    --continue
    -- "$DL_URL"
    )
  wget "${WGET_OPT[@]}" || return $?$(echo "E: wget failed: rv=$?" >&2)
  mv --verbose --no-clobber --no-target-directory \
    -- "$TMP_DL" "$SAVE_AS" || return $?
}


function unpack_tarball () {
  local TARBALL="$1"
  local UNP_DIR='unpack.tmp'
  echo "D: Unpacking files into '$UNP_DIR':"
  mkdir --parents -- "$UNP_DIR"
  local TAR_OPT=(
    --extract
    --directory="$UNP_DIR"
    # --verbose
    --restrict
    --no-same-owner
    # not supported for compressed tarballs: # --verify
    --ungzip
    --file "$TARBALL"
    )
  tar "${TAR_OPT[@]}" || return $?$(echo "E: tar unpack failed: rv=$?" >&2)

  local MMC_BIN="$SMMC_BASEDIR/${CFG[mmc_bin_dir]}"
  local INNER_ORIG="$MMC_BIN/orig_launcher.sh"
  local INNER_MODDED="$MMC_BIN/multimc_inner.sh"

  echo "D: Re-arranging files into '$MMC_BIN':"
  mkdir --parents -- "$MMC_BIN"
  mv --no-target-directory -- "$UNP_DIR"/MultiMC/bin/MultiMC \
    "$MMC_BIN/${CFG[mmc_elf_bfn]}" || return $?

  mv --no-target-directory \
    -- "$UNP_DIR"/MultiMC/MultiMC "$INNER_ORIG" || return $?
  chmod a-x -- "$INNER_ORIG" || return $?

  mv --target-directory="$MMC_BIN" \
    -- "$UNP_DIR"/MultiMC/bin/[A-Za-z]* || return $?
  rmdir -- "$UNP_DIR"/MultiMC/bin
  rmdir -- "$UNP_DIR"/MultiMC
  rmdir -- "$UNP_DIR" || return $?$(
    echo "E: Failed to clean up directory '$UNP_DIR'," \
      "maybe we forgot to move some files?")
  echo "D: Successfully cleaned up '$UNP_DIR'."

  echo 'D: Hotpatching launcher:'
  LANG=C sed -rf <(echo '
    1a HOME="\$(readlink -m -- "\$BASH_SOURCE"/..)"; export HOME; cd || exit 2
    s~/bin/MultiMC\b~/'"${CFG[mmc_elf_bfn]}"'~g
    s~^(\s*)(chmod \+x)~\1echo "D: skip: \2"~
    ') -- "$INNER_ORIG" >"$INNER_MODDED" || return $?
  chmod a+x -- "$INNER_MODDED" || return $?
  ln --symbolic --no-target-directory \
    -- "${INNER_MODDED##*/}" "$MMC_BIN/${CFG[sbx_inner_cmd]}" || return $?

  echo "D: Prepare launcher config:"
  prepare_mmc_ini || return $?

  echo 'D: Install succeeded.'
}


function prepare_mmc_ini () {
  local PERSI="$SMMC_BASEDIR/${CFG[persist_dir]}"
  mkdir --parents -- "$PERSI"
  local P_INI="$PERSI"/multimc.ini
  local DF_INI="$SMMC_BASEDIR/src/cfg/default_multimc.ini"
  [ -f "$P_INI" ] || grep -Pe '^\w' -- "$DF_INI" >"$P_INI" || return $?$(
    echo "E: Failed (rv=$?) to create config from defaults: $P_INI" >&2)
  local M_INI="$SMMC_BASEDIR/${CFG[mmc_bin_dir]}/multimc.cfg"
  [ -L multimc/multimc.cfg ] \
    || ln --symbolic --relative -- "$P_INI" "$M_INI" \
    || return $?$(echo "E: Failed (rv=$?) to create config symlink" >&2)
}









return 0
