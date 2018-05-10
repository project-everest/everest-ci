# This script create or updates the html log file that will be upload to azure.

param
(
    [Parameter(Mandatory=$true)]
    [String] $BuildNumber,
    [Parameter(Mandatory=$true)]
    [String] $BuildDefinitionName,
    [Parameter(Mandatory=$true)]
    [String] $ProjectName,
    [Parameter(Mandatory=$true)]
    [String] $GitCommitId,
    [Parameter(Mandatory=$true)]
    [String] $GitCommitLink,
    [Parameter(Mandatory=$true)]
    [String] $GitCommitMessage,
    [Parameter(Mandatory=$true)]
    [String] $GitCommitAuthor,
    [Parameter(Mandatory=$true)]
    [String] $GitCommitBranch,
    [Parameter(Mandatory=$true)]
    [String] $BuildDuration,
    [Parameter(Mandatory=$true)]
    [String] $OSName,
    [Parameter(Mandatory=$true)]
    [String] $BuildLogFile,
    [Parameter(Mandatory=$true)]
    [String] $UploadFileName
)

# Read the log file and rmeove first and last lines. Those represent start and finish of container.
$log = Get-Content $BuildLogFile | Select -Skip 1 | Select -SkipLast 1

# Replace lines to indicate errors as red lines.
$log = $log -replace "(\[STDOUT])(.*?)$","<p>`$2</p>"
$log = $log -replace "(\[STDERR])(.*?)$","<p><font color=`"red`">`$2</font></p>"

# Build Summary info.
$body = @"<table>
            <tr>
                <th>Project:</th>
                <td>$ProjectName</td>
            </tr>
            <tr>
                <th>Build Definition:</th>
                <td>$BuildDefinitionName</td>
            </tr>
            <tr>
                <th>Build Number:</th>
                <td>$BuildNumber</td>
            </tr>
            <tr>
                <th>Date Time:</th>
                <td>$(Get-Date)</td>
            </tr>
            <tr>
                <th>Commit:</th>
                <td><a href="$GitCommitLink">$GitCommitId</a></td>
            </tr>
            <tr>
                <th>Commit Message:</th>
                <td>$GitCommitMessage</td>
            </tr>
            <tr>
                <th>Commit Author:</th>
                <td>$GitCommitAuthor</td>
            </tr>
            <tr>
                <th>Build Duration:</th>
                <td>$BuildDuration</td>
            </tr>
            <tr>
                <th>OS:</th>
                <td>$OSName</td>
            </tr>
        </table>
        <hr><hr>
        <span>$log</span>"@

"<html><head><title>$BuildDefinitionName - Build:$BuildNumber</title></head>$body<body></body></html>" | Out-File $UploadFileName