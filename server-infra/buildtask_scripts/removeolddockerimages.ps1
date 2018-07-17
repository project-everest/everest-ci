# This script is responsible to remove all images older than 24 hours.

$knownImages = "ubuntu", "everest_base_image", "everest_windows_base_image", "microsoft/windowsservercore", "microsoft/nanoserver"

$images = docker images --format '{{json .}}' | ConvertFrom-Json
$images | ForEach-Object {
    if ($knownImages.Contains($_.Repository) -eq $false -and $_.Tag -ne "latest") {
        $info = docker inspect $_.Id | ConvertFrom-Json
        if (((Get-Date) - (Get-Date -Date $info.Metadata.LastTagTime)).TotalHours -gt 72) {
            docker rmi -f $_.ID
        }
    }
}