FROM microsoft/windowsservercore:1709
WORKDIR "C:\ewerest"

# WORKDIR "vs2017"
## NOTE: the URL obtained through GC Developer Console, Network tab,
## couldn't find an official direct URL
# ADD ["https://download.visualstudio.microsoft.com/download/pr/100196707/045b56eb413191d03850ecc425172a7d/vs_Community.exe"; "vs2017.exe"]
# RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --quiet
# WORKDIR ".."

WORKDIR "cygwin"
ADD ["http://cygwin.org/setup-x86_64.exe", "setup-x86_64.exe"]
# JP: this sleep command allows the container network to be set up, if the network is configured in transparent mode.
# (NAT mode may not work on all physical networks)
RUN powershell -Command "sleep 5" && .\setup-x86_64.exe --site http://mirrors.metapeer.com/cygwin --no-desktop --no-shortcuts --quiet-mode --verbose --no-startmenu --wait --packages=rsync,patch,diffutils,curl,make,unzip,git,m4,perl,mingw64-x86_64-gcc-core
WORKDIR ".."

# ADD ["https://raw.githubusercontent.com/project-everest/everest-ci/master/.docker/ewerest/install.sh", "install.sh"]
# RUN C:\Cygwin64\bin\bash.exe --login C:\ewerest\install.sh
