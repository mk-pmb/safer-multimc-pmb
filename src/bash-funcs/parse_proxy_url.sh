#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function parse_proxy_url () {
  local STORE="$1"; shift
  local PRX= PT= UN= PW=
  for PRX in "$@"; do
    case "$PRX" in
      '' ) ;;

      socks://* | \
      socks4://* | \
      socks4a://* | \
      https://* | \
      bogus: )
        echo "E: proxy type not supported: '$PRX'" >&2
        return 8;;

      socks5://* | \
      http://* )
        PT="${PRX%%:*}"
        PT="${PT%a}"
        PT="${PT%[45]}"
        PT="${PT^^}"
        eval "${STORE//%/Type}"'="$PT"'

        PRX="${PRX#*://}"
        PRX="${PRX%/}"
        UN="${PRX%%@*}"
        [ "$UN" == "$PRX" ] && UN=
        PRX="${PRX##*@}"
        PT=
        [[ "$PRX" =~ :([0-9]+)$ ]] && PT="${BASH_REMATCH[1]}"
        eval "${STORE//%/Addr}"'="${PRX%:$PT}"'
        eval "${STORE//%/Port}"'="$PT"'

        PW="${UN#*:}"
        [ "$PW" == "$UN" ] && PW=
        UN="${UN%%:*}"
        eval "${STORE//%/User}"'="$UN"'
        eval "${STORE//%/Pass}"'="$PW"'
        ;;

      * )
        echo "E: unsupported proxy URL syntax: '$PRX'" >&2
        return 8;;
    esac
  done
}


return 0
