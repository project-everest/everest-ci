# This script is responsible to define if a slack notification should be fired.

param
(
    [Parameter(Mandatory=$true)]
    [String] $BranchName,
    [Parameter(Mandatory=$true)]
    [String] $Channel
)

# We always send notificaiton if a change is being made on Master or if the branch name contains _sn
# _sn => slack notification
$slackEnabled = $BranchName -eq "Master" -or $BranchName -ilike "*_sn*"

if ($slackEnabled) {
    Write-Host "##vso[task.setvariable variable=SlackChannel]$Channel"
    Write-Host "##vso[task.setvariable variable=SlackDirectMessage]$false"
} else {
    if ($BranchName.indexof("_") -ne -1) {
        $user = $BranchName.Substring(0, $BranchName.indexof("_"))
        Write-Host "##vso[task.setvariable variable=SlackChannel]$user"
        Write-Host "##vso[task.setvariable variable=SlackDirectMessage]$true"
    }
}

