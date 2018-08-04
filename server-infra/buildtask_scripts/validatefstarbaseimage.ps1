# This script is responsible to validate the fstar base image to be used by child projects

param
(
    [Parameter(Mandatory=$true)]
    [String] $fstarversionFile
)

# Retrieve which base image we are trying to use.
$config = get-content $fstarversionFile | ConvertFrom-Json
$fstarBranchName = $config.branch
$commitId = $config.commit
Write-Host "##vso[task.setvariable variable=PartialCommitId]$commitId"

if ($commitId -eq "latest") {
    $commitInfo = Invoke-WebRequest -Uri "https://github.com/FStarLang/FStar/commit"
    $commitCapture = $commitInfo.Content | Select-String '((content=\"https:\/\/github.com\/FStarLang\/FStar\/commit\/)+([^\"]*))'
    $fullCommitId = $commitCapture.Matches.Groups[3].Value
    $commitId = $fullCommitId.Substring(0, 12)
}

$baseImage = "fstar:$commitId"
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