# This script uploads the extra logs to Azure
# Creates a markdown file that has the link for the log file on azure and add it to the VSTS build page.

param
(
    [Parameter(Mandatory=$true)]
    [String] $BuildLogFileUrl
)

"[Extra logs]($BuildLogFileUrl)" | Out-File extralog.md
$file = Get-Item .\extralog.md
Write-Host "##vso[task.addattachment type=Distributedtask.Core.Summary;name=Everest Logs;]$($file.FullName)"
