# This script is responsible to do the complete setup in order
# to have build agents running on the Windows build machine.

param
(
    [Parameter(Mandatory=$true, HelpMessage="VSTS Personal Access Token")]
    [string] $vstsPat
)

$Error.Clear()
$LastExitCode = 0

function ConfigAgents {
    Param ([string] $vstsPat, [int] $i, [bool] $shouldRemove)

    $args = "--unattended --url https://msr-project-everest.visualstudio.com --auth path --token $vstsPat --pool MsrEverestPoolWindows --agent $i --acceptTeeEula --runAsService"
    if ($shouldRemove) {
        $args = "remove", $args
    }

    Start-Process "$((Get-Location).Path)\config.cmd" -NoNewWindow -Wait -ArgumentList $args
}

$originalLocation = "$((Get-Location).Path)"

$numberOfAgents=8
.\bootstrap.ps1 $numberOfAgents

if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    return
}

Write-Host "Setup all agents."
$agentsFolder = "/home/builder/build/agents"
for ($i=1; $i -le $numberOfAgents; $i++) {
    Set-Location "$agentsFolder\agent-$i"

    # First we remove agent if it exists.
    ConfigAgents $vstsPat $i $true

    # Add agent
    ConfigAgents $vstsPat $i $false

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

# verify if everest base image exists.
$images = docker images -q everest_base_image:1 --format '{{json .}}' | ConvertFrom-Json
if ($null -eq $images -or $images.Count -eq 0) {
    # Build our Everest Windows base image
    docker build -f .docker/Dockerfile -t everest_base_image:1 .

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        $Error
        return
    }
}

Copy-Item "$originalLocation\..\buildtask_scripts" -Destination "c:\home\builder\buildtask_scripts" -Force -Recurse
Copy-Item "$originalLocation\..\config" -Destination "c:\home\builder\config" -Force -Recurse
write-host "Make sure to populate /home/builder/config/config.json file with correct settings."

write-host "Done with setup."
Set-Location $originalLocation
