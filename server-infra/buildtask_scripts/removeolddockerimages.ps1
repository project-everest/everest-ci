# This script is responsible to remove all images older than 24 hours.

$knownImages = "ubuntu", "everest_base_image", "microsoft/windowsservercore"

$images = docker images --format '{{json .}}' | ConvertFrom-Json
$images | ForEach-Object {
    # First we look for unfinished containers.
    # Any container not tag'ed (name equals to none) older than an hour should be removed.
    if ($_.Repository -eq "<none>" -or $_.Tag  -eq "<none>") {
        $createdAt = $_.CreatedAt.ToString().Replace(" PDT", "")
        if (((Get-Date) - (Get-Date -Date $createdAt)).TotalHours -gt 2) {
            write-host $_.Repository:$_.Tag $_.Id
            docker rmi -f $ $_.Id
        }
    }
    # Any known images should not be removed, and also any image tag'ed as latest.
    elseif ($knownImages.Contains($_.Repository) -eq $false -and $_.Tag -ne "latest") {
        # For all other images we should see when was the last time that image was touched.
        # If last time was older than 72 hours, then we should remove it.
        $info = docker inspect $_.Id | ConvertFrom-Json
        if (((Get-Date) - (Get-Date -Date $info.Metadata.LastTagTime)).TotalHours -gt 72) {
            write-host $_.Repository:$_.Tag $_.Id
            docker rmi -f $_.Id
        }
    }
}