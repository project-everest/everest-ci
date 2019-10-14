set -e
export OCAMLRUNPARAM=b
{ ./everest/everest --yes check 2>&1 ; } || true # this one is known to fail
eval $(opam config env)
./everest/everest --yes check
echo "End of build.sh"
