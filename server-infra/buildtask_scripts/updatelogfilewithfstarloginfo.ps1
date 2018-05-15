# This script create or updates the html log file that will be upload to azure.

param
(
    [Parameter(Mandatory=$true)]
    [String] $BuildNumber,
    [Parameter(Mandatory=$true)]
    [String] $UploadFileName
)

# Read the log file and rmeove first and last lines. Those represent start and finish of container.
$log = Get-Content $UploadFileName

$log = $log -replace "id='placeholder1' style='visibility:hidden'",""

$hints = Get-Content failed_hints.txt

$log = $log -replace "$th_placeholder1","$hints hints failed to replay"
$noreplay = "https://everestlogstorage.blob.core.windows.net/fstarlang-fstar/buildlogfile_$($BuildNumber)-log_no_replay.html"
$worst = "https://everestlogstorage.blob.core.windows.net/fstarlang-fstar/buildlogfile_$($BuildNumber)-log_worst.html"

$log = $log -replace "$td_placeholder1","(<a href='$noreplay'>not replayable</a>, <a href='$worst'>worst offenders</a>)"

$log | Out-File $UploadFileName