#!/bin/bash
#
# This script must be run in the directory that contains all the home
# dirs of the users of a previous machine.
# It will then copy the directories into /home, with the right ownership
# and add each user to the same groups as the current user.

set -e
set -x

for u in *
do
    sudo adduser --disabled-password --gecos $u $u &&
    sudo cp -p -r $u/. /home/$u &&
    sudo chown $u:$u /home/$u &&
    for g in $(groups)
    do
        sudo usermod -a -G $g $u
    done
done
