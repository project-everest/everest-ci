# This is the Everest Base Image
# Version 1
# If you make changes to this file, make sure to update the version above and rebuild the image,
# also update all references to use the new version, this image should be built using:
# docker build -f Dockerfile -t everest_base_image:$V .
# Where $V is the number of the version above
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Create user, with no password, and switch to user mode
# Subsequent RUN commands will fail if there is a password
RUN net user everest /add
RUN net localgroup Administrators everest /add
RUN wmic useraccount where "Name='everest'" set PasswordExpires=false
USER everest

# Enable IIS
RUN powershell -Command \
    Add-WindowsFeature Web-Server; \
    Invoke-WebRequest -UseBasicParsing -Uri "https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.3/ServiceMonitor.exe" -OutFile "C:\ServiceMonitor.exe"

# Install Powershell Core
ADD ["https://github.com/PowerShell/PowerShell/releases/download/v6.0.0/PowerShell-6.0.0-win-x64.zip", "c:/powershell.zip"]
RUN powershell.exe -Command Expand-Archive c:/powershell.zip c:/PS6; Remove-Item c:/powershell.zip
RUN C:/PS6/pwsh.EXE -Command C:/PS6/Install-PowerShellRemoting.ps1

# Enable SSH
ADD ["https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.0.0p1-Beta/OpenSSH-Win64.zip", "OpenSSH-Win64.zip"]
RUN c:/PS6/pwsh.exe -Command Expand-Archive OpenSSH-Win64.zip c:/; Remove-Item OpenSSH-Win64.zip
RUN c:/PS6/pwsh.exe -Command c:/OpenSSH-Win64/install-sshd.ps1
RUN c:/PS6/pwsh.exe -Command Set-Service sshd -StartupType Automatic
RUN c:/PS6/pwsh.exe -Command Set-Service ssh-agent -StartupType Automatic

# Configure SSH
COPY sshd_config c:/OpenSSH-Win64/sshd_config
COPY sshd_banner c:/OpenSSH-Win64/sshd_banner
COPY sshd_config C:/ProgramData/ssh/sshd_config
COPY sshd_banner C:/ProgramData/ssh/sshd_banner

WORKDIR c:/OpenSSH-Win64/
RUN c:/OpenSSH-Win64/ssh-keygen.exe -t dsa -N "" -f ssh_host_dsa_key
RUN c:/OpenSSH-Win64/ssh-keygen.exe -t rsa -N "" -f ssh_host_rsa_key
RUN c:/OpenSSH-Win64/ssh-keygen.exe -t ecdsa -N "" -f ssh_host_ecdsa_key
RUN c:/OpenSSH-Win64/ssh-keygen.exe -t ed25519 -N "" -f ssh_host_ed25519_key

# Set Powershell Core as default ssh shell
RUN C:/PS6/pwsh.EXE -Command \
    New-Item -Path HKLM:\SOFTWARE -Name OpenSSH -Force; \
    New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value c:\\ps6\\pwsh.exe -PropertyType string -Force;

# Fix ssh permissions
RUN C:/PS6/pwsh.EXE -Command \
    c:/OpenSSH-Win64/Install-sshd.ps1; \
    c:/OpenSSH-Win64/FixHostFilePermissions.ps1 -Confirm:$false;

WORKDIR 'c:\\cygwin64\\home\\everest'
COPY bash.ps1 .

# Set IIS virtual directory to point to Everest folder and then enable web directory browsing
RUN powershell.exe -Command Set-WebConfigurationProperty "\"system.applicationHost/sites/site[@name='Default Web Site']/application[@path='/']/virtualDirectory[@path='/']\"" -Name physicalPath -Value 'c:\cygwin64\home\everest'
RUN powershell.exe -Command Set-WebConfigurationProperty -filter /system.webServer/directoryBrowse -Name enabled -PSPath "\"IIS:\Sites\Default Web Site\"" -Value true

RUN powershell.exe -Command " \
    Get-WebBinding -Name \"Default Web Site\"; \
    cd cert:; \
    $cert = New-SelfSignedCertificate -DnsName  myweb -Friendlyname MyCert -CertStoreLocation Cert:\\LocalMachine\\My; \
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine; \
    $rootStore.Open(\"MaxAllowed\"); \
    $rootStore.Add($cert); \
    $rootStore.Close(); \
    cd iis:; \
    new-item -path IIS:\\SslBindings\\0.0.0.0!443 -value $cert; \
    New-WebBinding -Name \"Default Web Site\" -IP "*" -Port 443 -Protocol https; \
    Get-WebBinding -Name \"Default Web Site\"; "

# Install Windows SDK and .NET Framework 4.5 (not 4.5.x) needed to rebuild F* with F#
ADD ["https://aka.ms/vs/15/release/vs_community.exe", "vs2017.exe"]
RUN .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp \
    --quiet --nocache --norestart --wait
# --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop --add Microsoft.Net.Component.4.5.TargetingPack --add Microsoft.VisualStudio.Component.Roslyn.Compiler
RUN del vs2017.exe

# Set powershell as the default shell and add the script file
# to be load everytime powershell opens a new session.
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN .\bash.ps1; New-BashCmdProfile;
RUN Remove-Item 'bash.ps1'

WORKDIR "tools"

# Install cygwin
WORKDIR "cygwin"
ADD ["https://chocolatey.org/install.ps1", "install.ps1"]
RUN & .\install.ps1; choco install cygwin -y --params='/InstallDir:C:\\cygwin64 /NoStartMenu'

# Refresh environment variables.
RUN refreshenv; [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\\cygwin64\\bin;', [EnvironmentVariableTarget]::Machine)

# Install cygwin packages
ADD ["https://raw.githubusercontent.com/project-everest/everest/master/cygwin-packages", "cygwin-packages"]
RUN Get-Content cygwin-packages | ForEach-Object { choco install $_ --source cygwin }

WORKDIR ".."

# Install Madoko (we need nodejs)
RUN choco install nodejs -y
RUN refreshenv;
RUN npm install madoko -g

# Install Pandoc
RUN choco install pandoc -y

WORKDIR ".."

RUN Remove-Item .\tools -Force -Recurse

# Setup the user that will be used to interact with github.
RUN Invoke-BashCmd 'git config --global user.email \\\"everbld@microsoft.com\\\"'
RUN Invoke-BashCmd 'git config --global user.name \\\"Dzomo the everest Yak\\\"'

# Run everest check to install any missing piece
RUN Invoke-BashCmd 'git clone -b master --single-branch https://github.com/project-everest/everest.git'
#RUN Invoke-BashCmd 'TERM=cygwin ./everest/everest --yes check'
COPY build_helper.sh .
COPY build.sh .
RUN Invoke-BashCmd ./build_helper.sh $Env:BUILDTARGET $Env:BUILDLOGFILE $Env:MAXTHREADS $Env:BRANCHNAME
RUN Invoke-BashCmd rm build.sh build_helper.sh
RUN Invoke-BashCmd 'rm -rf .git'

# Setup bash prompt
COPY default_bashrc 'c:\\cygwin64\\home\\everest\\.bashrc'
RUN Invoke-BashCmd 'echo . ~/.bashrc | tee -a ~/.bash_profile'
RUN Invoke-BashCmd 'dos2unix ~/.bash_profile'

# Create a bash shortcut for when ssh connection is open, it automatically calls the bash
RUN echo 'c:/cygwin64/bin/bash.exe --login -I' > c:/ps6/Microsoft.PowerShell_profile.ps1

EXPOSE 22 80 443

# Copy ssh files
COPY authorized_keys 'c:\\Users\\everest\\.ssh\\authorized_keys'

COPY start.ps1 c:/start.ps1
ENTRYPOINT ["powershell.exe", "-NoExit", "c:/start.ps1"]
