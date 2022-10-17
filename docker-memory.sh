#!/usr/bin/env bash

# Track the maximum memory consumption of a Docker container while it is running
# Usage: $0 containerid

container=$1
timestamp=$(date "+%s")

print_time () {
    local now=$(date "+%s")
    local elapsed=$(($now - $timestamp))
    local hours=$(($elapsed / 60 / 60 ))
    local minutes=$((($elapsed / 60) % 60))
    if [[ $minutes -lt 10 ]] ; then minutes="0$minutes" ; fi
    local seconds=$(($elapsed % 60))
    if [[ $seconds -lt 10 ]] ; then seconds="0$seconds" ; fi
    echo -n "$hours:$minutes:$seconds "
}

max=0
while line=$(docker stats --no-stream $container) ; do
	memfield=$(echo "$line" | grep -v 'CONTAINER ID' | sed 's! \+! !g' | cut -d' ' -f4)
	numeric=$(echo "$memfield" | grep -o '[0-9.]*')
	unit=$(echo "$memfield" | sed 's![0-9.]*!!g')
	case $unit in
		('GiB')
		value=$(echo "$numeric * 1024 * 1024 * 1024" | bc | sed 's!\..*!!')
		;;
		('MiB')
		value=$(echo "$numeric * 1024 * 1024" | bc | sed 's!\..*!!')
		;;
		('KiB')
		value=$(echo "$numeric * 1024" | bc | sed 's!\..*!!')
		;;
		(*)
		value=$numeric
		;;
	esac
	if [[ $value -gt $max ]] ; then
		max=$value
                print_time
		echo "Peak memory consumption reached: $max"
	fi
	sleep 1
done
print_time
echo "End of process"
