# This script is responsible to remove all images older than 24 hours.

$knownImages = "ubuntu", "everest_base_image", "fstar_base_image", "mitls_base_image", "everest_windows_base_image", "microsoft/windowsservercore", "microsoft/nanoserver"

$images = docker images --format '{{json .}}' | ConvertFrom-Json
$images | ForEach-Object {
    if ($knownImages.Contains($_.Repository) -eq $false) {
        $created = $_.CreatedAt -ireplace " PDT", ""
        # Windows docker running in Azure reports times in GMT
        $created = $created -ireplace " GMT", ""
        if (((Get-Date) - (Get-Date -Date $created)).TotalHours -gt 1) {
            docker rmi -f $_.ID
        }
    }
}