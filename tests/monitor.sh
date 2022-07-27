#!/bin/sh

if [ -z "$POT_MONITOR_TMP" ]; then
	POT_MONITOR_TMP=$(mktemp /tmp/pot-monitor.XXXXXX) || exit 1
	touch "$POT_MONITOR_TMP" || exit 1
	export POT_MONITOR_TMP
fi

__mon_put()
{
        local k v
        k="$1"
        v="$@"
        echo "$k:$(echo "$v" | openssl base64 -A)" >>"$POT_MONITOR_TMP"
}

__mon_get()
{
        local k d r
        k="$1"
        d="$2"

        r="$(grep "^$k:" "$POT_MONITOR_TMP" | tail -n1 | cut -d : -f 2 | \
          openssl base64 -d)"
	if [ -n "$r" ]; then
		echo "$r"
	elif [ -n "$d" ]; then
		echo "$d"
	fi
}

__mon_load()
{
	local k v line
	
	while read -r line ; do
		k="$(echo "$line" | cut -d : -f 1)"
		v="$(echo "$line" | cut -d : -f 2)"
		if [ -n "$k" ]; then
			export "$k"="$(echo "$v" | openssl base64 -d)"
		fi
	done < "$POT_MONITOR_TMP"
}

__mon_zap()
{
	true >"$POT_MONITOR_TMP"
}

__monitor()
{
	local M i C
	i=0
	M=$1
	shift
	C="$(__mon_get "${M}_CALLS)" 0)"
	C=$(( C + 1 ))
	__mon_put C $C
	while [ -n "$1" ] || [ -n "$2" ] || [ -n "$3" ]; do
		i=$(( i + 1 ))
		__mon_put "${M}_CALL${C}_ARG${i}" "$1"
		shift
	done
}
