# This script will read config.json and load it into VSTS variables to be used during the build process.

param
(
    [Parameter(Mandatory=$true)]
    [String] $ConfigFileName,
    [Parameter(Mandatory=$true)]
    [String] $BuildId
)

If (!(Test-Path $ConfigFileName))
{
    Write-Host "Please provide a valid config file."
    exit(1);
}

# Load the build info file into an object.
$config = Get-Content -Raw -Path $ConfigFileName  | ConvertFrom-Json

Write-Host "##vso[task.setvariable variable=CommitInfoFileName]$($config.Build.CommitInfoFileName)"
Write-Host "##vso[task.setvariable variable=BuildLogFile]$($config.Build.LogFile)"

Write-Host "##vso[task.setvariable variable=AzureStorageAccount;issecret=true]$($config.Azure.StorageAccount)"
Write-Host "##vso[task.setvariable variable=AzureStorageAccessKey;issecret=true]$($config.Azure.StorageAccessKey)"

Write-Host "##vso[task.setvariable variable=SlackAccessToken;issecret=true]$($config.Slack.AccessToken)"



#### Load other variables

# Generate the name of the log file that should be upload to azure blob.
$uploadFile =  [System.IO.Path]::GetFileNameWithoutExtension($config.Build.LogFile) + "_" +  $BuildId + ".html"
Write-Host "##vso[task.setvariable variable=UploadFileName]$uploadFile"