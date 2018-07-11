# This script is responsible to generate some variables containing the github commit information.

param
(
    [Parameter(Mandatory=$true)]
    [String] $CommitInfoFileName,
    [Parameter(Mandatory=$true)]
    [String] $BuildRepositoryName
)

If (!(Test-Path $CommitInfoFileName))
{
    Write-Host "Please provide a valid file."
    exit(1);
}

# Load the commit info file into an object.
$commitInfo = Get-Content -Raw -Path $CommitInfoFileName  | ConvertFrom-Json

$message=$commitInfo.value[0].message -replace "`"","'"
Write-Host "##vso[task.setvariable variable=GitHubCommitMessage]$message"
Write-Host "##vso[task.setvariable variable=GitHubCommitAuthor]$($commitInfo.value[0].author.displayName)"
$gitHubCommitId = $commitInfo.value[0].id.Substring(0,12)
Write-Host "##vso[task.setvariable variable=GitHubCommitId]$gitHubCommitId"
Write-Host "##vso[task.setvariable variable=GitHubCommitLink]$($commitInfo.value[0].displayUri)"

$buildRequestedAuthor = $commitInfo.value[0].author.displayName.Replace(" ", "").ToLower()

# In case author has accented chars, we should remove it.
# We iterate over the string char by char checking if it is a valid char and removing invalid chars.
$author = ""
$buildRequestedAuthor = $buildRequestedAuthor.Normalize([System.Text.NormalizationForm]::FormD)
ForEach ($c in [char[]]$buildRequestedAuthor) {
    $unicodeCategory = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c);
    if ($unicodeCategory -ne [System.Globalization.UnicodeCategory]::NonSpacingMark)
    {
        $author += $c;
    }
}

$buildRequestedAuthor = $author.Normalize([System.Text.NormalizationForm]::FormC)


Write-Host "##vso[task.setvariable variable=BuildRequestedAuthor]$buildRequestedAuthor"

# Now we format the Container image name
$repoName = $BuildRepositoryName.Replace("/", "-").ToLower();
if ($repoName -match "-") {
    $repoName = $repoName.Split("-")[1]
}

Write-Host "##vso[task.setvariable variable=AzureRepositoryName]$repoName"

$containerImageName = "everestvstsacr.azurecr.io/" + $repoName + ":" + $gitHubCommitId
Write-Host "##vso[task.setvariable variable=ContainerImageName]$containerImageName"
