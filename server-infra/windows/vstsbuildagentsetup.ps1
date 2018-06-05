# This script is responsible to do the complete setup in order to have build agents running 
# on the Windows 1709 Container build machine.

param
(
  [Parameter(Mandatory=$true, HelpMessage="VSTS Personal Access Token")]
  [string] $vstsPat
)

function getAgent {
  Param ([int] $i, [string] $agentCommand)

  $a = "/home/builder/build/agents/agent-$i/" + $agentCommand
  $b = $a -replace '/','\' # powershell bug: Start-Process doesn't support '/' in paths.
  return $b
}

function configOrRemoveAgents {
  Param ([string] $vstsPat, [int] $i, [bool] $remove)

  $a = getAgent $i "config.cmd"
  $args = "--unattended --url https://msr-project-everest.visualstudio.com --auth path --token $vstsPat --pool MsrEverestPoolWindows --agent $i --acceptTeeEula --runAsService"
  if ($remove) {
    $args = "remove", $args
  }

  Start-Process $a -NoNewWindow -Wait -ArgumentList $args
}

function removeAgents {
  Param ([string] $vstsPat, [int] $i)

  configOrRemoveAgents $vstsPat $i $true
}

# this configures the agent as a Windows Service, and starts it immediately.
function configAgents {
  Param ([string] $vstsPat, [int] $i)

  configOrRemoveAgents $vstsPat $i $false
}

$numberOfAgents=8
.\bootstrap.ps1 $numberOfAgents

for ([int] $i=1; $i -le $numberOfAgents; $i++) {
  removeAgents $vstsPat $i
  configAgents $vstsPat $i
}

cd (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)

$hasImage = & docker images -q everest_windows_base_image:1 2>$null
if (-not $hasImage) {
  # Build our Everest Windows base image
  docker build -f .docker/Dockerfile -t everest_windows_base_image:1 .

  write-host "Make sure to copy buildtask_scripts and config folders to be under /home/builder"
  write-host "Make sure to populate config.json file with correct settings."
}

write-host "Done with setup."
