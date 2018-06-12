# Bootstrap a fresh "Windows Server 1709 Docker" OS

param
(
  [Parameter(Mandatory=$true)]
  [uint32] [ValidateRange(1,256)] $numberOfAgents
)

# Don't report progress... this speeds wget by 10x
$ProgressPreference = 'SilentlyContinue'
write-host "==== Bootstrap ===="

#disable password prompts on sudo
#disable ssh password auth
#upgrade OS
#set hostname if needed

# create /home/builder/build if needed
$build_dir = "/home/builder/build"
mkdir -Force $build_dir | Out-Null
cd $build_dir

#install azure CLI
write-host "Installing Azure CLI"
$azure_cli_msi = $build_dir+"/azurecli.msi"
# although PowerShell accepts '/' as a path character almost everywhere,
# Start-Process does not.  It requires '\' or else it fails with file-not-found.
$azure_cli_msi_dos = $azure_cli_msi -replace "/","\"
wget "https://aka.ms/installazurecliwindows" -outfile /home/builder/build/azurecli.msi
Start-Process $azure_cli_msi_dos  -Wait -ArgumentList /passive
# it is installed to "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

#install git
write-host "Installing Git"
# powershell defaults to TLS 1.0, which github.com does not support.  Switch to 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
wget "https://github.com/git-for-windows/git/releases/download/v2.17.1.windows.2/Git-2.17.1.2-64-bit.exe" -outfile git_setup.exe
Start-Process git_setup.exe -Wait -ArgumentList "/SILENT /NORESTART /DIR=c:\Git"
# add it to the path, both locally in this shell, and machine-wide
$env:path+=";c:\git\bin"
[System.Environment]::SetEnvironmentVariable("PATH", $Env:path, "Machine")

#install node.js
wget https://nodejs.org/dist/v8.11.2/node-v8.11.2-x64.msi -outfile:node_setup.msi
Start-Process msiexec.exe -Wait -ArgumentList "/i node.msi INSTALLDIR=c:\Node /passive"
$env:path+=";c:\node"
[System.Environment]::SetEnvironmentVariable("PATH", $Env:path, "Machine")

# create /home/builder/build/agents
$agents_dir = $build_dir+"/agents"
mkdir -Force $agents_dir | Out-Null

# download the VSTS windows agent to that directory
write-host "Downloading VSTS Windows Agent"
$agent_zip = $agents_dir+"/vsts-agent.zip"
wget "https://vstsagentpackage.azureedge.net/agent/2.134.2/vsts-agent-win-x64-2.134.2.zip" -outfile $agent_zip

# for each in $numberOfAgents
#  create agent-# subdir
#  copy the agent binary into the subdir and extract from the downloaded .zip
for ($i=1; $i -le $numberOfAgents; $i++) {
  write-host "Unzipping agent $i"
  $agentNumber = $agents_dir+"/agent-$i"
  if (! (Test-Path $agentNumber)) {
    mkdir $agentNumber | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory($agent_zip, $agentNumber)
  }
}

Write-Host "Bootstrap done."

