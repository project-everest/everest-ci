# This is the Everest Base Image
# Version 1
# If you make changes to this file, make sure to update the version above and rebuild the image,
# also update all references to use the new version, this image should be built using:
# docker build -f Dockerfile -t everest_base_image:$V .
# Where $V is the number of the version above
FROM microsoft/windowsservercore:ltsc2016
WORKDIR "C:\ewerest"

# Create a new user, with no password.  It will become the
# default user context for new Docker commands to run in
# after the CI build completes.  The 'everest' user
# account will be password-protected, meaning it can be
# accessed via SSH, but not Docker, as Docker has no way
# to pass a password through to CreateProcessAsUser()
RUN net user root /add
RUN net localgroup Administrators root /add

# Create user, with no password, and switch to user mode
# Subsequent RUN commands will fail if there is a password
RUN net user everest /add
RUN net localgroup Administrators everest /add
USER everest

# This script runs its command line UAC-elevated.  It is needed
# for RUN commands that run in the context of the Everest user.
COPY sudo.ps1 .
COPY bash.ps1 .

# Install Windows SDK and .NET Framework 4.5 (not 4.5.x) needed to rebuild F* with F#
ADD ["https://aka.ms/vs/15/release/vs_community.exe", "vs2017.exe"]
RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop --add Microsoft.Net.Component.4.5.TargetingPack --quiet --wait
RUN del vs2017.exe

# Install cygwin
WORKDIR "cygwin"
ADD ["https://chocolatey.org/install.ps1", "install.ps1"]
RUN powershell.exe c:\ewerest\cygwin\install.ps1
RUN powershell.exe -Command "choco install cygwin -y --params='/InstallDir:C:\cygwin64 /NoStartMenu'"
RUN del install.ps1

# Refresh environment variables.
RUN powershell.exe -Command "refreshenv"
RUN powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\tools\cygwin\bin', [EnvironmentVariableTarget]::Machine)"

# Install cygwin packages
ENV EVEREST_BRANCH master
ADD ["https://raw.githubusercontent.com/project-everest/everest/$EVEREST_BRANCH/cygwin-packages", "everest-packages"]
RUN powershell.exe -Command "Get-Content everest-packages | ForEach-Object { choco install $_ --source cygwin }"
RUN del everest-packages

# configure Cygwin home directory to be the Windows home directory (c:\users\everest)
RUN echo db_home:windows >> C:\cygwin64\etc\nsswitch.conf
WORKDIR ".."

COPY everestcheck.sh .
RUN C:\cygwin64\bin\bash.exe --login /cygdrive/c/ewerest/everestcheck.sh

# TODO Enable SSH
#WORKDIR "openssh"
#ADD ["https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.0.0p1-Beta/OpenSSH-Win64.zip", "OpenSSH-Win64.zip"]
#RUN powershell.exe Expand-Archive OpenSSH-Win64.zip
#RUN powershell.exe OpenSSH-Win64\OpenSSH-Win64\install-sshd.ps1
#RUN powershell.exe Set-Service sshd -StartupType Automatic
#RUN powershell.exe Set-Service ssh-agent -StartupType Automatic
#WORKDIR ".."

# Used by downstream Dockerfiles
ENV MYHOME c:\\users\\everest

ENTRYPOINT ["powershell.exe"]

EXPOSE 22 80