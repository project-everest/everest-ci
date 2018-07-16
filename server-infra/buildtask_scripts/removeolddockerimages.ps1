# This script is responsible to remove all images older than 24 hours.

$knownImages = "ubuntu", "everest_base_image", "everest_windows_base_image", "microsoft/windowsservercore", "microsoft/nanoserver"

$images = docker images --format '{{json .}}' | ConvertFrom-Json
$images | ForEach-Object {
    if ($knownImages.Contains($_.Repository) -eq $false -and $_.Tag -ne "latest") {
        $image = "$($images[0].Repository):$($images[0].Tag)"
        $info = docker inspect $image | ConvertFrom-Json
        if (((Get-Date) - (Get-Date -Date $info.Metadata.LastTagTime)).TotalHours -gt 72) {
            docker rmi -f $_.ID
        }
    }
}