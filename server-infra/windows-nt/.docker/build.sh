export OCAMLRUNPARAM=b
./everest/everest --yes check
eval $(opam config env)
./everest/everest --yes check
echo "End of build.sh"
