# This script create or updates the html log file that will be upload to azure.

param
(
    [Parameter(Mandatory=$true)]
    [String] $UploadFileName
)

$container= Get-Content -Raw -Path container.json  | ConvertFrom-Json
$IpAddress = $container.ipAddress.ip

# Read the log file and rmeove first and last lines. Those represent start and finish of container.
$log = Get-Content $UploadFileName

$log = $log -replace " id='placeholder6' style='visibility:hidden'",""

$log = $log -replace "th_placeholder6", "Connect to Container"
$log = $log -replace "td_placeholder6", "ssh everest@$IpAddress<br>Password: Docker!"

Remove-Item $UploadFileName -Force
$log | Out-File $UploadFileName