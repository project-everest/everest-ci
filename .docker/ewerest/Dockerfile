FROM microsoft/windowsservercore:1709
WORKDIR "C:\ewerest"

WORKDIR "vs2017"
## NOTE: the URL obtained through GC Developer Console, Network tab,
## couldn't find an official direct URL
ADD ["https://download.visualstudio.microsoft.com/download/pr/100196707/045b56eb413191d03850ecc425172a7d/vs_Community.exe"; "vs2017.exe"]
RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --quiet
WORKDIR ".."

WORKDIR "python"
ENV PYTHON_VER 2.7.13
ADD ["https://www.python.org/ftp/python/$PYTHON_VER/python-$PYTHON_VER.amd64.msi", "python.msi"]
RUN msiexec /i python.msi /quiet
ENV PATH C:\Python27;C:\Python27\Scripts;$PATH
WORKDIR ".."

# NOTE: we need to install cygwin before scons,
# because cygwin provides unzip

WORKDIR "cygwin"
ADD ["http://cygwin.org/setup-x86_64.exe", "setup-x86_64.exe"]
# JP: prefix any command requiring network with:
# powershell -Command "sleep 5" && 
# this sleep command allows the container network to be set up, if the network is configured in transparent mode.
# (NAT mode may not work on all physical networks)
RUN .\setup-x86_64.exe --site http://mirrors.metapeer.com/cygwin --no-desktop --no-shortcuts --quiet-mode --verbose --no-startmenu --wait --packages=rsync,patch,diffutils,curl,make,unzip,git,m4,perl,mingw64-x86_64-gcc-core,wget
WORKDIR ".."

WORKDIR "scons"
ENV SCONS_VER 3.0.0
ADD ["http://downloads.sourceforge.net/scons/scons-$SCONS_VER.zip", "scons.zip"]
RUN C:\Cygwin64\bin\unzip.exe C:\ewerest\scons\scons.zip
WORKDIR "scons-"$SCONS_VER
RUN python setup.py install
WORKDIR "..\.."

ADD ["https://raw.githubusercontent.com/project-everest/everest-ci/taramana_ewerest/.docker/ewerest/install.sh", "install.sh"]
RUN C:\Cygwin64\bin\bash.exe --login C:\ewerest\install.sh
