# This script create or updates the html log file that will be upload to azure.

param
(
    [Parameter(Mandatory=$true)]
    [String] $IpAddress,
    [Parameter(Mandatory=$true)]
    [String] $UploadFileName
)

# Read the log file and rmeove first and last lines. Those represent start and finish of container.
$log = Get-Content $UploadFileName

$log = $log -replace " id='placeholder6' style='visibility:hidden'",""

$log = $log -replace "th_placeholder6", "Container Ip Address"
$log = $log -replace "td_placeholder6", $IpAddress

Remove-Item $UploadFileName -Force
$log | Out-File $UploadFileName