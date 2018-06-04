cd /cygdrive/c/ewerest/opam
tar -xf opam.tar.xz
bash opam64/install.sh
opam init mingw 'https://github.com/fdopen/opam-repository-mingw.git' --comp $OCMAL_VER+mingw64c --switch $OCMAL_VER+mingw64c -y
echo ". '/.opam/opam-init/init.sh' > /dev/null 2> /dev/null || true" >>/.profile

