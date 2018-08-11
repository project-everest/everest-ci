# This script is responsible to validate the fstar base image to be used by child projects

param
(
    [Parameter(Mandatory=$true)]
    [String] $fstarversionFile
)

# if version does not exist then we don't need a base image.
if ((Test-Path "$fstarversionFile") -eq $false) {
    Write-Host "##vso[task.setvariable variable=BaseImageFound]$true"
    return
}

# Retrieve which base image we are trying to use.
$config = get-content $fstarversionFile | ConvertFrom-Json
$fstarBranchName = $config.branch
$commitId = $config.commit

if ($commitId -eq "latest") {
    $commitInfo = Invoke-WebRequest -Uri "https://github.com/FStarLang/FStar/commit"
    $commitCapture = $commitInfo.Content | Select-String '((content=\"https:\/\/github.com\/FStarLang\/FStar\/commit\/)+([^\"]*))'
    $fullCommitId = $commitCapture.Matches.Groups[3].Value
    $commitId = $fullCommitId.Substring(0, 12)
}

Write-Host "##vso[task.setvariable variable=PartialCommitId]$commitId"

# this is the name of the image we are looking for
$baseImage = "fstar:$commitId"

# the image we are looking for should have this string in the args
$fstarSourceVersion = "FSTARSOURCEVERSION=$fullCommitId"

$baseImageFound = $false

while ($true) {
    write-host "Looking for base image."
    $shouldBreak = $true

    # Query all images.
    $images = docker images --format '{{json .}}' | ConvertFrom-Json
    $images | ForEach-Object {
        # for each image retrieve the image name.
        $imageName = $_.Repository + ":" + $_.Tag

        # inspect the image.
        # If the image has the args we are looking for, but the name of the image is not the base image
        # it means we are still building the image, so we should wait 1 minute and retry.
        $info = docker inspect $_.Id | ConvertFrom-Json
        if ($info.ContainerConfig.Cmd -icontains $fstarSourceVersion) {
            write-host "Found expected image."

            # if image has the name we are looking for we are done.
            if ($imageName -eq $baseImage) {
                # tag the image to renew usage and prevent it to be deleted.
                docker tag $imageName $imageName
                write-host "Found base image."
                $baseImageFound = $true
            } else {
                # lets make sure it is not a dead image.
                # if it is older than 1 hour and has not the expected name, we skip it.
                $createdAt = $_.CreatedAt.ToString().Replace(" PDT", "")
                if (((Get-Date) - (Get-Date -Date $createdAt)).TotalHours -lt 1) {
                    # sleep 1 min and don't break outerloop.
                    write-host "Waiting for image $($_.Id) to be built."
                    Start-Sleep -Seconds 30
                    $shouldBreak = $false;
                }
            }
        }
    }

    if ($shouldBreak -eq $false) {
        continue
    }

    break
}

Write-Host "##vso[task.setvariable variable=BaseImageFound]$baseImageFound"

# If we still have not found it, then we should request a new build.
if ($baseImageFound -eq $false) {
    Write-Host "##vso[task.setvariable variable=FStarBranchName]$fstarBranchName"
    $fullCommitId = ""

    if ($commitId -ne "latest") {
        $commitInfo = Invoke-WebRequest -Uri "https://github.com/FStarLang/FStar/commit/$commitId"
        $commitCapture = $commitInfo.Content | Select-String '((content=\"https:\/\/github.com\/FStarLang\/FStar\/commit\/)+([^\"]*))'
        $fullCommitId = $commitCapture.Matches.Groups[3].Value
        Write-Host "##vso[task.setvariable variable=FullCommitId]$fullCommitId"
    }

    Write-Host "##vso[task.setvariable variable=FullCommitId]$fullCommitId"
}