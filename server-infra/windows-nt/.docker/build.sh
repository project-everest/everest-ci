set -e
export OCAMLRUNPARAM=b
ctr=5
while [[ $ctr -gt 0 ]] && ! ./everest/everest --yes check
do
    ctr=$(($ctr - 1))
done
echo "End of build.sh"
[[ $ctr -gt 0 ]] && eval $(opam config env)
