#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function verify_tarball () {
  local TARBALL="$1"; shift
  local TRUST_LIST="$1"; shift
  case "$TRUST_LIST" in
    */* ) ;;
    * ) TRUST_LIST="$SMMC_BASEDIR/src/cfg/$TRUST_LIST";;
  esac

  local DL_SIZE="$(stat -c %s -- "$TARBALL")"
  local HASH_ALGO='sha512'
  local DL_HASH="$("$HASH_ALGO"sum --binary -- "$TARBALL" \
    | LANG=C sed -re 's~ .*$~~; s~\S{8}~ &~g; s~^ ~~')"
  local DL_CFPR="size $DL_SIZE $HASH_ALGO $DL_HASH"
  DL_CFPR="${DL_CFPR// /_}"
  echo "D: Downloaded tarball content fingerprint: $DL_CFPR"
  grep -qFe '* `'"$DL_CFPR"'`' -- "$TRUST_LIST" || return 4$(
    echo "E: Downloaded tarball is not listed as trusted." \
      "This usually indicates a corrupted download." >&2)
  echo "D: Found that fingerprint in trust list. Gonna extract."
}


return 0
