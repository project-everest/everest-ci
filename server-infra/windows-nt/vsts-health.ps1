# This script is responsible to check if VSTS agent service has stopped.
# It starts the service in case the service is stopped.
# We have witness some situations where the Service crashes and does not restart by itself.

# This is script should be manually copied to the build server machine and
# a Windows Task scheduler should be add to run this script every X minutes.

$svcs = Get-Service "vsts*"

$svcs | ForEach-Object {
    if ($_.Status -ne "Running") {
        Start-Service $_.Name
    }
}

# Here we check if Docker service is up and running
$svcs = Get-Service "Docker"
$svcs | Write-Output "C:\home\builder\check health\log.txt"
$svcs | ForEach-Object {
    if ($_.Status -ne "Running") {
        Start-Service $_.Name | Write-Output "C:\home\builder\check health\log.txt"
    }
}

# Another way to check if Docker is in trouble, even if service says it is running.
$LASTEXITCODE = 0
docker stats --no-stream
if ($LASTEXITCODE -ne 0) {
    $svcs = Get-Service "Docker"
    $svcs | ForEach-Object {
        Stop-Service $_.Name
        Start-Service $_.Name
    }
}