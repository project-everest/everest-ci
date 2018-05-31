# Bootstrap a fresh "Windows Server 1709 Docker" OS

param
(
  [Parameter(Mandatory=$true)]
  [uint32] [ValidateRange(1,256)] $numberOfAgents
)

# Don't report progress... this speeds wget by 10x
$ProgressPreference = 'SilentlyContinue'

#disable password prompts on sudo
#disable ssh password auth
#upgrade OS
#set hostname if needed

# create /home/builder/build if needed
$build_dir = "/home/builder/build"
mkdir -Force $build_dir | Out-Null
cd $build_dir

#install .net if needed
#install powershell if needed
#install azure CLI
$azure_cli_msi = $build_dir+"/azurecli.msi"
# although PowerShell accepts '/' as a path character almost everywhere,
# Start-Process does not.  It requires '\' or else it fails with file-not-found.
$azure_cli_msi_dos = $azure_cli_msi -replace "/","\"
wget "https://aka.ms/installazurecliwindows" -outfile /home/builder/build/azurecli.msi
Start-Process $azure_cli_msi_dos  -Wait -ArgumentList /passive
# it is installed to "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

#install docker

# create /home/builder/build/agents
$agents_dir = $build_dir+"/agents"
mkdir -Force $agents_dir | Out-Null

# download the VSTS windows agent to that directory
$agent_zip = $agents_dir+"/vsts-agent.zip"
wget "https://vstsagentpackage.azureedge.net/agent/2.134.2/vsts-agent-win-x64-2.134.2.zip" -outfile $agent_zip

# for each in $numberOfAgents
#  create agent-# subdir
#  copy the agent binary into the subdir and extract from the downloaded .zip
for ($i=0; $i -lt $numberOfAgents; $i++) {
  $agentNumber = $agents_dir+"/agent-$i"
  if (! (Test-Path $agentNumber)) {
    mkdir $agentNumber | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory($agent_zip, $agentNumber)
  }
}

Write-Host "Bootstrap done."
