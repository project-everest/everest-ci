# Bootstrap a fresh "Windows Server 1709 Docker" OS

param
(
  [Parameter(Mandatory=$true)]
  [uint32] [ValidateRange(1,256)] $numberOfAgents
)

# Don't report progress... this speeds wget by 10x
$ProgressPreference = 'SilentlyContinue'
write-host "==== Bootstrap ===="

# powershell defaults to TLS 1.0, which many sites don't support.  Switch to 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
$env:path+=";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
[System.Environment]::SetEnvironmentVariable("PATH", $Env:path, "Machine")

#install git
write-host "Installing Git"
wget "https://github.com/git-for-windows/git/releases/download/v2.17.1.windows.2/Git-2.17.1.2-64-bit.exe" -outfile git_setup.exe
Start-Process git_setup.exe -Wait -ArgumentList "/SILENT /NORESTART /DIR=c:\Git"
# add it to the path, both locally in this shell, and machine-wide
$env:path+=";c:\git\bin"
[System.Environment]::SetEnvironmentVariable("PATH", $Env:path, "Machine")

#install docker-machine
write-host "Installing docker-machine"
wget -UseBasicParsing https://github.com/docker/machine/releases/download/v0.15.0/docker-machine-Windows-x86_64.exe -outfile "c:\Program Files\Docker\docker-machine.exe"

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

# The VSTS agents run as NetworkService, which has little local access to the machine.
# The Docker service's named pipe defaults to only allowing admin users.  So bridge the
# two via a group called "docker"
net localgroup docker /add
net localgroup docker NetworkService /add
Add-Content -Path C:\ProgramData\Docker\config\daemon.json -Value '{ "group" : "docker" }' -Encoding Ascii
Start-Process sc.exe -Wait -ArgumentList "stop docker"
Start-Process sc.exe -Wait -ArgumentList "start docker"

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

