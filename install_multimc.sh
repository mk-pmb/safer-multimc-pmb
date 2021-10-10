#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function install_multimc () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

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
  verify_tarball "$SAVE_AS" || return $?
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


function verify_tarball () {
  local TARBALL="$1"
  local DL_SIZE="$(stat -c %s -- "$TARBALL")"
  local HASH_ALGO='sha512'
  local DL_HASH="$("$HASH_ALGO"sum --binary -- "$TARBALL" \
    | LANG=C sed -re 's~ .*$~~; s~\S{8}~ &~g; s~^ ~~')"
  local DL_CFPR="size $DL_SIZE $HASH_ALGO $DL_HASH"
  DL_CFPR="${DL_CFPR// /_}"
  echo "D: Downloaded tarball content fingerprint: $DL_CFPR"
  local TRUSTED=
  grep -qFe '* `'"$DL_CFPR"'`' -- trusted_tarballs.md || return 4$(
    echo "E: Downloaded tarball is not listed as trusted." \
      "This usually indicates a corrupted download." >&2)
  echo "D: Found that fingerprint in trust list. Gonna extract."
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

  local BIN_DIR='multimc'
  local ELF_BFN='multimc_core.elf'
  local LAUNCHER="$BIN_DIR/multimc_inner.sh"

  echo "D: Re-arranging files into '$BIN_DIR':"
  mkdir --parents -- "$BIN_DIR"
  mv --no-target-directory \
    -- "$UNP_DIR"/MultiMC/bin/MultiMC "$BIN_DIR/$ELF_BFN" || return $?

  mv --no-target-directory \
    -- "$UNP_DIR"/MultiMC/MultiMC "$LAUNCHER".orig || return $?
  chmod a-x -- "$LAUNCHER".orig || return $?

  mv --target-directory="$BIN_DIR" \
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
    s~/bin/MultiMC\b~/'"$ELF_BFN"'~g
    s~^(\s*)(chmod \+x)~\1echo "D: skip: \2"~
    ') -- "$LAUNCHER".orig >"$LAUNCHER" || return $?
  chmod a+x -- "$LAUNCHER" || return $?
  ln --symbolic --no-target-directory --  "$(basename -- "$LAUNCHER"
    )" "$(dirname -- "$LAUNCHER")/multimc-sandboxed" || return $?

  echo 'D: Install succeeded.'
}









install_multimc "$@"; exit $?
