# This script will analyze build log files

param
(
    [Parameter(Mandatory=$true)]
    [String] $BuildLogFile
)

# Calculate build time
$logContent = get-content $BuildLogFile
$start = $logContent | Select-Object -first 1
$end =  $logContent | Select-Object -last 1
$BuildContainerTime = (Get-Date -Date $end) - (Get-Date -Date $start)
Write-Host "##vso[task.setvariable variable=BuildContainerTime]$BuildContainerTime"

$content = Get-Content "result.txt"
if ($null -eq $content) {
    $content = "Failure"
}

$buildStatus = "danger"
if ($null -ne $content -and $content -eq "Success") {
    $buildStatus = "good"
} elseif ($null -ne $content -and $content.StartsWith("Success with breakages")) {
    $buildStatus = "warning"
} else {
    # this is a failure, try to retrieve what is failing
    # Get all the lines of the form: path\to\foo.fst(111,11-111,11) : (Error...
    # something. Erase the path while at it, keeping the filename only.
    $result = $logContent | Select-String '^((\[STDERR\]+)((.)*)\((.)*\):\s\(Error\s(.)*\)(.)*)$'
    if ($result.Matches.Count -gt 0) {
        $failedModules = ""
        $result.Matches |  ForEach-Object {
            if ($failedModules.Length -gt 0) {
                $failedModules += ", "
            }

            $failedModules += $_.Groups[3].Value
        }

        if ($failedModules.Length -gt 0) {
            $content += " - There were errors in: " + $failedModules
        }
    }
}

Write-Host "##vso[task.setvariable variable=BuildStatus]$buildStatus"
Write-Host "##vso[task.setvariable variable=BuildResult]$content"
