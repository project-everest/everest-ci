# This script is responsible to validate if container should be removed.

param
(
    [Parameter(Mandatory=$true)]
    [String] $BranchName
)

$knownBranches = "master", "main", "fstar-master"

Write-Host "##vso[task.setvariable variable=ShouldRemoveContainerImage]$($knownBranches.Contains($BranchName) -eq $false)"
