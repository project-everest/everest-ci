# Bootstrap a fresh Windows Server OS to become a build agent server.

$Error.Clear()
$LastExitCode = 0

$ProgressPreference = 'SilentlyContinue'
Write-Host "==== Bootstrap ===="

# powershell defaults to TLS 1.0, which many sites don't support.  Switch to 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# create /home/builder/build if needed
$build_dir = "/home/builder/build"
mkdir -Force $build_dir | Out-Null
Set-Location $build_dir

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

$Error.Clear()
Write-Host "Install Cygwin with git"
wget "https://www.cygwin.com/setup-x86_64.exe" -outfile "cygwinsetup.exe"
cmd.exe /c start /wait .\cygwinsetup.exe -q --root C:\cygwin64 -P git,wget -X
Remove-Item "cygwinsetup.exe"
if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

$Error.Clear()
Write-Host "Install Visual Studio"
wget "https://aka.ms/vs/15/release/vs_community.exe" -outfile "vs2017.exe"
cmd.exe /c start /wait .\vs2017.exe --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.NuGet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop --add Microsoft.Net.Component.4.5.TargetingPack --add Microsoft.VisualStudio.Component.Roslyn.Compiler --quiet --wait
Remove-Item vs2017.exe
if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

$Error.Clear()
Write-Host "Install bash.ps1"
wget "https://raw.githubusercontent.com/project-everest/everest-ci/master/server-infra/windows-nt/.docker/bash.ps1" -outfile "bash.ps1"
.\bash.ps1
New-BashCmdProfile
Remove-Item bash.ps1
if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

$Error.Clear()
Write-Host "Install everest dependencies"
wget "https://github.com/project-everest/everest/archive/master.zip" -outfile "everest-master.zip"
Expand-Archive -Path everest-master.zip -DestinationPath .
Invoke-BashCmd "everest-master/everest --yes check"
Remove-Item "everest-master.zip"
if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

Write-Host "Bootstrap done."
$Error.Clear()
