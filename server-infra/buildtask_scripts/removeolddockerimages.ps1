# This script is responsible to remove all images older than 24 hours.

$knownImages = "ubuntu", "everest_base_image", "fstar_base_image"

$images = docker images --format '{{json .}}' | ConvertFrom-Json
$images | ForEach-Object {
    if ($knownImages.Contains($_.Repository) -eq $false) {
        $created = $_.CreatedAt -ireplace " PDT", ""
        if (((Get-Date) - (Get-Date -Date $created)).Days -gt 0) {
            docker rmi -f $_.ID
        }
    }
}