cd /cygdrive/c/ewerest/opam
tar -xf opam.tar.xz
bash opam64/install.sh
opam init mingw 'https://github.com/fdopen/opam-repository-mingw.git' --comp $OCAML_VER+mingw64c --switch $OCAML_VER+mingw64c -y > opaminstall.log 2>&1
echo ". '/home/everest/.opam/opam-init/init.sh' > /dev/null 2> /dev/null || true" >>/home/everest/.bash_profile

