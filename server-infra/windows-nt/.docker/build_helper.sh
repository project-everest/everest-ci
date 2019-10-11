#!/usr/bin/env bash

set -e

out_file=buildlog.txt

# Add ssh identity
eval $(ssh-agent)
ssh-add .ssh/id_rsa

echo $(date -u "+%Y-%m-%d %H:%M:%S") >> $out_file

tail -f $out_file &
tail_pd=$!
{ { { { { { stdbuf -e0 -o0 ./build.sh ; } 3>&1 1>&2 2>&3 ; } | sed -u 's!^![STDERR]!' ; } 3>&1 1>&2 2>&3 ; } | sed -u 's!^![STDOUT]!' ; } 2>&1 ; } >> $out_file
echo "Build finished" >> $out_file
kill $tail_pd

echo "======= TRYING TO GET THE END OF THE LOG ======"
tail -n 100 $out_file
echo "======= END TRYING TO GET THE END OF THE LOG ======"

echo $(date -u "+%Y-%m-%d %H:%M:%S") >> $out_file

eval $(ssh-agent)
ssh-add -D
