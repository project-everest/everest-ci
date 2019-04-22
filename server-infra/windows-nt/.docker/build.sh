export OCAMLRUNPARAM=b
./everest/everest --yes check 2>&1
eval $(opam config env)
./everest/everest --yes check
echo "End of build.sh"
