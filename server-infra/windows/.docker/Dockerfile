FROM microsoft/windowsservercore:1709
WORKDIR "C:\ewerest"

WORKDIR "vs2017"
ADD ["https://aka.ms/vs/15/release/vs_community.exe", "vs2017.exe"]
# Windows SDK needed by Vale
# .NET Framework 4.5 (not 4.5.x) needed to rebuild F* with F#
# (everest FStar verify, make -C FStar/src)
RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop --add Microsoft.Net.Component.4.5.TargetingPack --quiet --wait
WORKDIR ".."

WORKDIR "python"
ENV PYTHON_VER 3.6.5
ADD ["https://www.python.org/ftp/python/$PYTHON_VER/python-$PYTHON_VER-amd64.exe", "pythonsetup.exe"]
RUN pythonsetup.exe /quiet TargetDir=c:\\Python PrependPath=1 IncludeDoc=0
# ENV does not support quoting PATH for Windows images,
# so take solution adapted from:
# https://stackoverflow.com/questions/42092932/appending-to-path-in-a-windows-docker-container
#RUN ["powershell", "-Command", "[Environment]::SetEnvironmentVariable('Path', 'C:\\Python;C:\\Python\\Scripts;' + $env:Path, [EnvironmentVariableTarget]::Machine)"]
WORKDIR ".."

ENV EVEREST_BRANCH master

# NOTE: we need to install cygwin before scons,
# because cygwin provides unzip

WORKDIR "cygwin"
ADD ["http://cygwin.org/setup-x86_64.exe", "setup-x86_64.exe"]
ADD ["https://raw.githubusercontent.com/project-everest/everest/$EVEREST_BRANCH/cygwin-packages", "everest-packages"]
RUN ["powershell", "-Command", "('.\\setup-x86_64.exe --site http://mirrors.metapeer.com/cygwin --no-desktop --no-shortcuts --quiet-mode --verbose --no-startmenu --wait --packages=' + ((cat everest-packages) -join ',') + ',rsync,patch,diffutils,curl,make,unzip,git,m4,perl,mingw64-x86_64-gcc-core,wget') | Out-File runsetup.bat -Encoding ASCII"]
RUN .\runsetup.bat
WORKDIR ".."

WORKDIR "scons"
ENV SCONS_VER 3.0.0
# ADD does not seem to support such redirections as SourceForge's
RUN C:\Cygwin64\bin\wget.exe http://prdownloads.sourceforge.net/scons/scons-%SCONS_VER%.zip
RUN C:\Cygwin64\bin\unzip.exe C:\ewerest\scons\scons-%SCONS_VER%.zip
WORKDIR "scons-"$SCONS_VER
RUN python setup.py install
WORKDIR "..\.."

WORKDIR "opam"
ENV OPAM_VER 0.0.0.1
ENV OCMAL_VER 4.06.0
ADD ["https://github.com/fdopen/opam-repository-mingw/releases/download/$OPAM_VER/opam64.tar.xz", "opam.tar.xz"]
COPY installopam.sh .
RUN C:\Cygwin64\bin\bash.exe --login c:\ewerest\opam\installopam.sh
WORKDIR ".."

# Set the final directory entrypoint
COPY everestcheck.sh .
ENV EVEREST_ENV_DEST_FILE ${MYHOME}/.profile
RUN C:\Cygwin64\bin\bash.exe --login /cygdrive/c/ewerest/everestcheck.sh

EXPOSE 22 80
