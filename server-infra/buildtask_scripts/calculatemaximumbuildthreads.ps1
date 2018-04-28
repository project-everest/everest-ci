# This script will detemrine based on current machine how many threads we should use for each build task.

# TODO: Add logic to come up with correct numer of threads. For now we will leave it hard code as 48

$buildMaxThreads = 48

Write-Host "##vso[task.setvariable variable=BuildMaxThreads]$buildMaxThreads"