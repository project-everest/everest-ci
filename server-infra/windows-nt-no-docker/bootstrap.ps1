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

Write-Host "Install Cygwin with git"
$Error.Clear()
wget "https://www.cygwin.com/setup-x86_64.exe" -outfile "cygwinsetup.exe"
.\cygwinsetup.exe -q --root C:\cygwin64 -P git,wget -X
Remove-Item "cygwinsetup.exe"
if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

Write-Host "Bootstrap done."
$Error.Clear()
