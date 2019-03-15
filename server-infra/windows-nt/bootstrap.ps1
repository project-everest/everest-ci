# Bootstrap a fresh Windows Server OS to become a build agent server.

$Error.Clear()
$LastExitCode = 0

# Rename machine name.
# Server machine should have a name that starts with Everest-Win*
if (($env:COMPUTERNAME -ilike "Everest-Win*") -eq $false) {
    # Enable Remote Desktop
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    # Rename machine
    Write-Host "Machine needs to be renamed and a restart is required."
    Write-Host "Restarting machine, please re-run script once it is back."
    Start-Sleep -Seconds 10
    Rename-Computer -NewName "Everest-Win-Bld" -Force -Restart -Confirm:$false
}

$ProgressPreference = 'SilentlyContinue'
Write-Host "==== Bootstrap ===="

# powershell defaults to TLS 1.0, which many sites don't support.  Switch to 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# create /home/builder/build if needed
$build_dir = "/home/builder/build"
mkdir -Force $build_dir | Out-Null
Set-Location $build_dir

# install dotnet core
Write-Host "Install dotnetCore if not present."
$dotnetCoreExists = (Get-Command dotnet -ErrorAction:SilentlyContinue)
if ($null -eq $dotnetCoreExists) {
    $Error.Clear()

    # Download script to install dotnet runtime
    Write-Host "Download dotnet core install script."
    wget "https://dot.net/v1/dotnet-install.ps1" -outfile "dotnet-install.ps1"
    Write-Host "Installing dotnet core pre-reqs"
    ./dotnet-install.ps1
    Remove-Item "dotnet-install.ps1"

    $Error.Clear()

    # Now that all dependencies of dotnet core are installed install dontnet core sdk 2.0
    Write-Host "Download and Install dotnetCore SDK"
    wget "https://download.microsoft.com/download/9/D/2/9D2354BE-778B-42D6-BA4F-3CEF489A4FDE/dotnet-sdk-2.2.105-win-x64.exe" -outfile "dotnet_sdk_setup.exe"
    Start-Process dotnet_sdk_setup.exe -Wait -ArgumentList "-q"
    Remove-Item "dotnet_sdk_setup.exe"

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

Write-Host "Install Azure CLI if not present."
$azExists = (Get-Command az -ErrorAction:SilentlyContinue)
if ($null -eq $azExists) {
    $Error.Clear()

    # install azure CLI
    Write-Host "Installing Azure CLI"
    wget "https://aka.ms/installazurecliwindows" -outfile "azurecli.msi"
    Start-Process msiexec.exe -Wait -ArgumentList "/i azurecli.msi /passive"
    Remove-Item "azurecli.msi"

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

#install git
Write-Host "Install GIT if not present."
$gitExists = (Get-Command git -ErrorAction:SilentlyContinue)
if ($null -eq $gitExists) {
    $Error.Clear()

    Write-Host "Installing Git"
    wget "https://github.com/git-for-windows/git/releases/download/v2.17.1.windows.2/Git-2.17.1.2-64-bit.exe" -outfile "git_setup.exe"
    Start-Process git_setup.exe -Wait -ArgumentList "/SILENT /NORESTART /DIR=c:\Git"
    Remove-Item "git_setup.exe"

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

#install docker-machine
Write-Host "Install Docker if not present."
$dockerExists = (Get-Command docker -ErrorAction:SilentlyContinue)
if ($null -eq $dockerExists) {
    $Error.Clear()

    Write-Host "Installing Docker"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name DockerMsftProvider -Force
    Install-Package -Name docker -ProviderName DockerMsftProvider -Update -Force

    Write-Host "Restarting machine, please re-run script once it is back."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}

if ((Test-Path "C:\ProgramData\Docker\config\daemon.json") -eq $false) {
    # The VSTS agents run as NetworkService, which has little local access to the machine.
    # The Docker service's named pipe defaults to only allowing admin users.  So bridge the
    # two via a group called "docker"
    net localgroup docker /add
    net localgroup docker NetworkService /add
    Add-Content -Path C:\ProgramData\Docker\config\daemon.json -Value '{ "group" : "docker" }' -Encoding Ascii

    Stop-Service docker
    Start-Service docker
    $Error.Clear()
}

if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

#install node.js
Write-Host "Install Node.js if not present."
$nodeExists = (Get-Command npm -ErrorAction:SilentlyContinue)
if ($null -eq $nodeExists) {
    $Error.Clear()

    Write-Host "Installing Node.js"
    wget https://nodejs.org/dist/v8.11.2/node-v8.11.2-x64.msi -outfile "node_setup.msi"
    Start-Process msiexec.exe -Wait -ArgumentList "/i node_setup.msi INSTALLDIR=c:\Node /passive"
    Remove-Item "node_setup.msi"

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }

    Write-Host "Restarting machine, please re-run script once it is back."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}

Write-Host "Install TypeScript if not present."
$tscExists = (Get-Command tsc -ErrorAction:SilentlyContinue)
if ($null -eq $tscExists) {
    $Error.Clear()

    # Install typescript
    Write-Host "Installing TypeScript"
    npm install -g typescript

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

Write-Host "Bootstrap done."
$Error.Clear()
