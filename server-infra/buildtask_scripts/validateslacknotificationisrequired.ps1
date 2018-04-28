# This script is responsible to define if a slack notification should be fired.

param
(
    [Parameter(Mandatory=$true)]
    [String] $BranchName
)

# We always send notificaiton if a change is being made on Master or if the branch name contains _sn
# _sn => slack notification
$slackEnabled = $BranchName -eq "Master" -or $BranchName -ilike "*_sn*"

Write-Host "##vso[task.setvariable variable=SlackEnabled]$slackEnabled"