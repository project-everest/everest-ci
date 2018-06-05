cd /cygdrive/c
git clone https://github.com/project-everest/everest.git everest --depth 1
cd everest
rm -rf .git
./everest --yes check
