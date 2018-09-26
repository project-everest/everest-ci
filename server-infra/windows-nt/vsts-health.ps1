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