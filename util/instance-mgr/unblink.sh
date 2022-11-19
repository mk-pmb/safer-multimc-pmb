#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function unblink_cli () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  # cd -- "$SELFPATH" || return $?

  local TASK="${1:-default_tasks}"
  unblink_"$TASK"
  local RV=$?
  [ "$RV" == 0 ] || sleep 2s
  smart-less-pmb -e git sup --untracked-files=all -- .
  return "$RV"
}


function unblink_default_tasks () {
  fixup_one_file 'instance.cfg' || return $?

  ensure_git_ignore . '
    /natives/
    /natives/ # auto-created and auto-removed(!!) by MultiMC.
    /saves    # in case you store them here
    ' || return $?

  ensure_git_ignore dotmc '
    /bin
    /icon.png
    /logs
    /mods
    /shaderpacks
    /usercache.json
    ' || return $?

  ensure_git_ignore dotmc/config/WindowTitleChanger '
    /icons/
    ' || return $?

  ensure_git_ignore dotmc/.fabric '
    /processedMods/
    /remappedJars/
    ' || return $?

  ensure_git_ignore dotmc/XaeroWorldMap '
    /*/*/.lock
    /*/*/cache
    /*/*/cache_*
    ' || return $?

  find dotmc/XaeroWorldMap/ -type f -name '*_config.txt' -empty -delete
  find dotmc/XaeroWaypoints_BACKUP* -type d -empty -delete 2>/dev/null

  ensure_git_ignore dotmc/config/worldedit '
    /.archive-unpack
    ' || return $?

  ensure_git_ignore dotmc/config/roughlyenoughitems '
    /changelog.txt
    ' || return $?

  rm --one-file-system -- dotmc/crash-reports/crash-20*-client.txt 2>/dev/null

  with_each_textfile fixup_one_file || return $?

  fixup_one_file 'mmc-pack.json' || return $?
  fixup_one_file 'dotmc/options.txt' || return $?
}


function with_each_textfile () {
  local LIST=(
    dotmc/config/
    dotmc/XaeroWorldMap/
    )
  readarray -t LIST < <(find_text_files "${LIST[@]}")
  local ITEM=
  for ITEM in "${LIST[@]}"; do
    "$@" "$ITEM" || return $?
  done
}


function find_text_files () {
  local FIND=(
    -type f
    '(' -false
      -o -name '*.hjson'
      -o -name '*.json'
      -o -name '*.json[0-9]'
      -o -name '*.properties'
      -o -name '*.toml'
      -o -name '*.txt'
      -o -name '*.yaml'
      -o -name '*.yml'
      ')'
    )
  find "$@" "${FIND[@]}"; return $?
}


function fixup_one_file () {
  local ITEM="$1"; shift
  [ -s "$ITEM" ] || return 3$(
    echo "E: Flinch: Empty original file: $ITEM" >&2)

  local TX="$(sed -re 's~\s+$~~' -- "$ITEM")"
  local SED=

  case "$ITEM" in
    *.json ) TX="$(<<<"$TX" json-sort-pmb)";;

    dotmc/options.txt | \
    instance.cfg | \
    //vsort// ) TX="$(<<<"$TX" LANG=C sort --version-sort)";;
  esac

  case "$ITEM" in
    *.properties )
      SED='2s~^# *([A-Z][a-z]{2} ){2}[ 0-9:]+ CES?T 20[0-9]{2}~# (date)~';;

    instance.cfg )
      SED='
        s~^($\
          |lastTimePlayed|$\
          |lastLaunchTime|$\
          |totalTimePlayed|$\
          )=[0-9]+$~\1=0~
        ';;

  esac

  [ -z "$SED" ] || TX="$(<<<"$TX" sed -rf <(echo "$SED"))"
  [ -n "$TX" ] || return 4$(
    echo "E: File would be empty after cleanup: $ITEM" >&2)

  case "$ITEM" in

    dotmc/XaeroWorldMap/*/server_config.txt )
      case "${TX//$'\n'/ }" in
        'multiworldType:0 ignoreServerLevelId:false ignoreHeightmaps:false' | \
        __boring_defaults__ )
          rm -- "$ITEM" || return $?
          return 0;;
      esac;;

  esac

  echo "$TX" >"$ITEM" || return $?$(
    echo "E: Failed to write file: $ITEM" >&2)
}


function ensure_git_ignore () {
  local DIR="$1"; shift
  [ -d "$DIR" ] || return 0
  local PATT="$1"; shift
  PATT="$(<<<"$PATT" sed -nre 's~^\s+~~;/\S/p')"
  local GI="$DIR/.gitignore"
  [ -s "$GI" ] || echo >>"$GI" || return $?
  local HAVE="$(cat -- "$GI")"
  local MISS="$(<<<"$PATT" grep -vxFe "$HAVE")"

  if [ -n "$MISS" ]; then
    [ -n "$HAVE" ] && HAVE+=$'\n'
    HAVE+=$'\n'"$MISS"
    echo "$HAVE" >"$GI" || return $?$(echo "E: Failed to update $GI" >&2)
  fi

  git add -- "$GI" || return $?$(echo "E: Failed to git add $GI" >&2)
}










unblink_cli "$@"; exit $?
