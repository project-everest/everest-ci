# This script is responsible to do the complete setup in order to have build agents running 
# on the Windows 1709 Container build machine.

param
(
  [Parameter(Mandatory=$true, HelpMessage="VSTS Personal Access Token")]
  [string] $vstsPat
)

function runAgent {
  Param (
    [Parameter(Mandatory=$true)][int] $i,
    [Parameter(Mandatory=$true)][string] $agentCommand,
    [Parameter(Mandatory=$false)]'[string] $agentArgument
  )

  $a = "/home/builder/build/agents/agent-$i/" + $agentCommand
  $b = $a -replace '/','\' # powershell bug: Start-Process doesn't support '/' in paths.
  write-host $b

  if ($agentArgument) {
    Start-Process $b -ArgumentList $agentArgument -NoNewWindow -Wait
  } else {
    Start-Process $b -NoNewWindow -Wait
  }
}

function removeAgents {
  Param ([string] $vstsPat, [int] $i)

  runAgent $i "config.cmd" "remove"
}

function configAgents {
  Param ([string] $vstsPat, [int] $i)

  runAgent $i "config.cmd"
}

function startAgents {
  Param ([string] $vstsPat, [int] $i)

  runAgent $i "run.cmd"
}

$numberOfAgents=8
.\bootstrap.sh $numberOfAgents

for ([int] $i=0; $i -lt $numberOfAgents; $i++) {
  removeAgents $vstsPat $i
  configAgents $vstsPat $i
  startAgents  $vstsPat $i
}