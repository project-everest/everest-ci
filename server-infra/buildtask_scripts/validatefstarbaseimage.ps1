# This script is responsible to validate the fstar base image to be used by child projects

# Retrieve which base image we are trying to use.
$containerContent = get-content "Dockerfile"
$capture = $containerContent | Select-String '^(FROM )((.)*:([^$]*))'
$baseImage = $capture.Matches.Groups[2].Value

$baseImageFound = $false

# Query all images and verify if we found the image we are looking for.
$images = docker images --format '{{json .}}' | ConvertFrom-Json
$images | ForEach-Object {
    $image = $_.Repository + ":" + $_.Tag
    if ($image -eq $baseImage) {
        docker tag $image $image
        $baseImageFound = $true
        break
    }
}

Write-Host "##vso[task.setvariable variable=BaseImageFound]$baseImageFound"

if ($baseImageFound -eq $false) {
    $commitId = $capture.Matches.Groups[4].Value
    $commitInfo = Invoke-WebRequest -Uri "https://github.com/FStarLang/FStar/commit/$commitId"
    $commitCapture = $commitInfo.Content | Select-String '((content=\"https:\/\/github.com\/FStarLang\/FStar\/commit\/)+([^\"]*))'
    $fullCommitId = $commitCapture.Matches.Groups[3].Value
    Write-Host "##vso[task.setvariable variable=FullCommitId]$fullCommitId"
}
