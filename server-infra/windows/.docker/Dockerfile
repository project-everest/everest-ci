FROM microsoft/windowsservercore:1709
WORKDIR "C:\ewerest"

# This script runs its command line UAC-elevated.  It is needed
# for RUN commands that run in the context of the Everest user.
COPY sudo.ps1 .

WORKDIR "vs2017"
ADD ["https://aka.ms/vs/15/release/vs_community.exe", "vs2017.exe"]
# Windows SDK needed by Vale
# .NET Framework 4.5 (not 4.5.x) needed to rebuild F* with F#
# (everest FStar verify, make -C FStar/src)
RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop --add Microsoft.Net.Component.4.5.TargetingPack --quiet --wait
WORKDIR ".."

WORKDIR "openssh"
ADD ["https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.0.0p1-Beta/OpenSSH-Win64.zip", "OpenSSH-Win64.zip"]
RUN powershell.exe Expand-Archive OpenSSH-Win64.zip
RUN powershell.exe OpenSSH-Win64\OpenSSH-Win64\install-sshd.ps1
RUN powershell.exe Set-Service sshd -StartupType Automatic
RUN powershell.exe Set-Service ssh-agent -StartupType Automatic
WORKDIR ".."

WORKDIR "python"
ENV PYTHON_VER 2.7.13
ADD ["https://www.python.org/ftp/python/$PYTHON_VER/python-$PYTHON_VER.amd64.msi", "pythonsetup.msi"]
RUN msiexec.exe /i pythonsetup.msi /quiet TargetDir=c:\\Python PrependPath=1 IncludeDoc=0
# ENV does not support quoting PATH for Windows images,
# so take solution adapted from:
# https://stackoverflow.com/questions/42092932/appending-to-path-in-a-windows-docker-container
RUN ["powershell", "-Command", "[Environment]::SetEnvironmentVariable('Path', 'C:\\Python;C:\\Python\\Scripts;' + $env:Path, [EnvironmentVariableTarget]::Machine)"]
WORKDIR ".."

WORKDIR "scons"
ENV SCONS_VER 2.5.1
# the URL comes from the "Problem downloading?" link on sourceforge.
ADD ["https://downloads.sourceforge.net/project/scons/scons/2.5.1/scons-2.5.1.zip?r=&ts=1528233878", "scons.zip"]
RUN powershell.exe Expand-Archive scons.zip
RUN python.exe scons/scons-%SCONS_VER%/setup.py install
WORKDIR ".."

# Create user, with no password, and switch to user mode
# Subsequent RUN commands will fail if there is a password
RUN net user everest /add
RUN net localgroup Administrators everest /add
USER everest

ENV EVEREST_BRANCH master

WORKDIR "cygwin"
ADD ["http://cygwin.org/setup-x86_64.exe", "setup-x86_64.exe"]
ADD ["https://raw.githubusercontent.com/project-everest/everest/$EVEREST_BRANCH/cygwin-packages", "everest-packages"]
RUN ["powershell", "-Command", "('.\\setup-x86_64.exe --site http://mirrors.metapeer.com/cygwin --no-desktop --no-shortcuts --quiet-mode --verbose --no-startmenu --wait --packages=' + ((cat everest-packages) -join ',') + ',rsync,patch,diffutils,curl,make,unzip,git,m4,perl,mingw64-x86_64-gcc-core,wget') | Out-File runsetup.bat -Encoding ASCII"]
RUN powershell.exe c:\ewerest\sudo.ps1 .\runsetup.bat
WORKDIR ".."

WORKDIR "opam"
ENV OPAM_VER 0.0.0.1
ENV OCAML_VER 4.06.0
ADD ["https://github.com/fdopen/opam-repository-mingw/releases/download/$OPAM_VER/opam64.tar.xz", "opam.tar.xz"]
COPY installopam.sh .
RUN powershell.exe c:\ewerest\sudo.ps1 C:\Cygwin64\bin\bash.exe --login c:\ewerest\opam\installopam.sh
# dump out the results of the opam install, generated from inside cygwin.  cygwin stdout doesn't appear in docker's output.
RUN cmd.exe /c type opaminstall.log
WORKDIR ".."

# Set the final directory entrypoint
COPY everestcheck.sh .
#ENV EVEREST_ENV_DEST_FILE /home/everest/.profile
RUN C:\Cygwin64\bin\bash.exe --login /cygdrive/c/ewerest/everestcheck.sh

EXPOSE 22 80

# now assign the password.  From this point onward, RNU will not work, and
# docker commands like exec will not be able to launch processes either.
# The only access is via SSH.
RUN net user everest Docker!
