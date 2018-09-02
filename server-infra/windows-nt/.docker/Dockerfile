# This is the Everest Base Image
# Version 1
# If you make changes to this file, make sure to update the version above and rebuild the image,
# also update all references to use the new version, this image should be built using:
# docker build -f Dockerfile -t everest_base_image:$V .
# Where $V is the number of the version above
FROM microsoft/windowsservercore:ltsc2016

WORKDIR 'c:\\cygwin64\\home\\everest'
COPY bash.ps1 .

# Install Windows SDK and .NET Framework 4.5 (not 4.5.x) needed to rebuild F* with F#
ADD ["https://aka.ms/vs/15/release/vs_community.exe", "vs2017.exe"]
RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop --add Microsoft.Net.Component.4.5.TargetingPack --quiet --wait
RUN del vs2017.exe

# Set powershell as the default shell and add the script file
# to be load everytime powershell opens a new session.
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN .\bash.ps1; New-BashCmdProfile;
RUN Remove-Item 'bash.ps1'

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

WORKDIR "tools"

# Install cygwin
WORKDIR "cygwin"
ADD ["https://chocolatey.org/install.ps1", "install.ps1"]
RUN & .\install.ps1; choco install cygwin -y --params='/InstallDir:C:\\cygwin64 /NoStartMenu'

# Install Python 2
ADD ["https://raw.githubusercontent.com/project-everest/everest/master/cygwin-packages", "cygwin-packages"]
RUN choco install python2 -y

# Refresh environment variables.
RUN refreshenv; [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\\cygwin64\\bin;C:\\Python27\\;', [EnvironmentVariableTarget]::Machine)

# Install cygwin packages
ADD ["https://raw.githubusercontent.com/project-everest/everest/master/cygwin-packages", "cygwin-packages"]
RUN Get-Content cygwin-packages | ForEach-Object { choco install $_ --source cygwin }
WORKDIR ".."

# Install Scons
WORKDIR "scons"
ADD ["https://downloads.sourceforge.net/project/scons/scons/3.0.1/scons-3.0.1.zip?ts=1535119051", "scons-3.0.1.zip"]
RUN Expand-Archive scons-3.0.1.zip; python scons-3.0.1/scons-3.0.1/setup.py install; Remove-Item scons-3.0.1.zip
WORKDIR ".."

# TODO Enable SSH
#WORKDIR "openssh"
#ADD ["https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.0.0p1-Beta/OpenSSH-Win64.zip", "OpenSSH-Win64.zip"]
#RUN powershell.exe Expand-Archive OpenSSH-Win64.zip
#RUN powershell.exe OpenSSH-Win64\OpenSSH-Win64\install-sshd.ps1
#RUN powershell.exe Set-Service sshd -StartupType Automatic
#RUN powershell.exe Set-Service ssh-agent -StartupType Automatic
#WORKDIR ".."

WORKDIR ".."

# Setup the user that will be used to interact with github.
RUN Invoke-BashCmd git config --global user.email '\"everbld@microsoft.com\"'
RUN Invoke-BashCmd git config --global user.name '\"Dzomo the everest Yak\"'

# Run everest check to install any missing piece
RUN Invoke-BashCmd git clone https://github.com/project-everest/everest.git
RUN Invoke-BashCmd ./everest/everest --yes check
RUN Invoke-BashCmd '. ''.opam/opam-init/init.sh'' > /dev/null 2> /dev/null || true'
RUN Invoke-BashCmd 'eval ''$(opam config env)'''
RUN Invoke-BashCmd rm -rf .git

ENTRYPOINT ["powershell.exe"]

EXPOSE 22 80