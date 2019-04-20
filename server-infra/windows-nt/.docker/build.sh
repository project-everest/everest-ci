export OCAMLRUNPARAM=b
./everest/everest --yes check
eval $(opam config env)
echo "End of build.sh"
./everest/everest --yes check
