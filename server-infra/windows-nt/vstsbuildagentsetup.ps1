# This script is responsible to do the complete setup in order
# to have build agents running on the Windows build machine.

param
(
    [Parameter(Mandatory=$true, HelpMessage="VSTS Personal Access Token")]
    [string] $vstsPat,
    [Parameter(Mandatory=$false, HelpMessage="Agent pool name")]
    [string] $poolName = "MsrEverestPoolWindows",
    [Parameter(Mandatory=$false, HelpMessage="Initial pool name index")]
    [int] $initialPoolIndex = 1,
    [Parameter(Mandatory=$false, HelpMessage="Finally pool name index")]
    [int] $finalPoolIndex = 4
)

$Error.Clear()
$LastExitCode = 0

function ConfigAgents {
    Param ([string] $vstsPat, [string] $poolName, [int] $i, [bool] $shouldRemove)

    $args = "--unattended --url https://msr-project-everest.visualstudio.com --auth path --token $vstsPat --pool $poolName --agent $i --acceptTeeEula --runAsService"
    if ($shouldRemove) {
        $args = "remove", $args
    }

    Start-Process "$((Get-Location).Path)\config.cmd" -NoNewWindow -Wait -ArgumentList $args
}

$originalLocation = "$((Get-Location).Path)"

.\bootstrap.ps1

if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

# create /home/builder/build/agents
$agents_dir = "$($(Get-Location).Path)\agents"
mkdir -Force $agents_dir | Out-Null

# download the VSTS windows agent to that directory
write-host "Downloading VSTS Windows Agent"
wget "https://vstsagentpackage.azureedge.net/agent/2.134.2/vsts-agent-win-x64-2.134.2.zip" -outfile "$agents_dir\vsts-agent.zip"

Add-Type -AssemblyName System.IO.Compression.FileSystem

# for each agent
#  create agent-# subdir
#  copy the agent binary into the subdir and extract from the downloaded .zip
for ($i=$initialPoolIndex; $i -le $finalPoolIndex; $i++) {
    $agent = "$((Get-Location).Path)\agents\agent-$i"
    if ((Test-Path "$agent") -eq $false) {
        mkdir "$agent" | Out-Null
        write-host "Unzipping agent $i on $agent"
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$agents_dir\vsts-agent.zip", "$agent")
    }
}

# Now do the same but for the ondemand agent.
for ($i=$initialPoolIndex; $i -le $finalPoolIndex; $i++) {
    $agent = "$((Get-Location).Path)\agents\agent-ondemand-$i"
    if ((Test-Path "$agent") -eq $false) {
        mkdir "$agent" | Out-Null
        write-host "Unzipping agent $i on $agent"
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$agents_dir\vsts-agent.zip", "$agent")
    }
}

Remove-Item "$agents_dir\vsts-agent.zip"

Write-Host "Setup all agents."
$agentsFolder = "/home/builder/build/agents"
for ($i=$initialPoolIndex; $i -le $finalPoolIndex; $i++) {
    Set-Location "$agentsFolder\agent-$i"

    # First we remove agent if it exists.
    ConfigAgents $vstsPat $poolName $i $true
    ConfigAgents $vstsPat $poolName-ondemand $i $true

    # Add agent
    ConfigAgents $vstsPat $poolName $i $false
    ConfigAgents $vstsPat $poolName-ondemand $i $false

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

write-host "Done with setup."
Set-Location $originalLocation
