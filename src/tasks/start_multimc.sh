#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function smmc_task_start_multimc () {
  local SBX_STUFF="$SMMC_BASEDIR/jail-stuff"
  mkdir --parents -- "$SBX_STUFF"
  chmod a=rx,ug+w -- "$SBX_STUFF" || return $?$(
    echo "E: Failed (rv=$?) to adjust permissions for '$SBX_STUFF'" >&2)

  local U_NAME="${CFG[sbx_user_name]}"
  local U_HOME="${CFG[sbx_user_home]}"

  local XAUTH_TMP="$(mktemp)"
  xauth extract - "$DISPLAY" | xauth -f "$XAUTH_TMP" merge -
  xauth -f "$XAUTH_TMP" generate :0 . untrusted || return $?$(
    echo "E: Failed to generate an untrusted xauth cookie in $XAUTH_TMP" >&2)
  sudo chown --reference "$U_HOME" -- "$$XAUTH_TMP" || return $?$(
    echo "E: Failed to chown the xauth cookie file $XAUTH_TMP" >&2)

  local JAIL_CMD=(
    sudo
    --user="$U_NAME"
    --set-home
    'debian_chroot'='smmc'
    'XAUTHORITY'=
    # gxmessage
    --

    firejail
    --debug
    --shell=/bin/bash
    # --noprofile
    # --bind=/usr/games/multimc,"$SELFPATH"
    # --private="$MMC_HOME"
    # --private=/usr/games/multimc
    # --private-cwd
    # --disable-mnt
    # --hosts-file=

    # --build="$SBX_STUFF/multimc.jail.cfg"
    # --chroot="$MMC_ABS_HOME"

#    --apparmor
#    --trace="$SBX_STUFF/multimc.trace.log"
#    --caps.drop=all
#    --hostname='shovel'
#    --join-or-start="$SBX_NAME"
#    --nodbus
#    --nonewprivs
#
#    # restrict hardware access
#    --private-dev
#    --nodvd
#    --notv
#    --nou2f
    # --x11=xorg

    # command
    # --
    bash -i
    # "./${CFG[mmc_bin_dir]}/${CFG[sbx_inner_cmd]}"
    )

  exec &> >(tee -- sandbox.log)
  exec "${JAIL_CMD[@]}"; return $?
}












return 0
