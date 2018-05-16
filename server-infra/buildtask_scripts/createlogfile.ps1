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
$body = "<h1>Build Summary</h1><br><br><table>
            <tr>
                <th style='text-align:left'>Project:</th>
                <td>$ProjectName</td>
            </tr>
            <tr>
                <th style='text-align:left'>Build Definition:</th>
                <td>$BuildDefinitionName</td>
            </tr>
            <tr>
                <th style='text-align:left'>Build Number:</th>
                <td>$BuildNumber</td>
            </tr>
            <tr>
                <th style='text-align:left'>Date Time:</th>
                <td>$(Get-Date)</td>
            </tr>
            <tr>
                <th style='text-align:left'>Commit:</th>
                <td><a href='$GitCommitLink'>$GitCommitId</a></td>
            </tr>
            <tr>
                <th style='text-align:left'>Commit Message:</th>
                <td>$GitCommitMessage</td>
            </tr>
            <tr>
                <th style='text-align:left'>Commit Author:</th>
                <td>$GitCommitAuthor</td>
            </tr>
            <tr>
                <th style='text-align:left'>Build Duration:</th>
                <td>$BuildDuration</td>
            </tr>
            <tr>
                <th style='text-align:left'>OS:</th>
                <td>$OSName</td>
            </tr>
            <tr id='placeholder1' style='visibility:hidden'>
                <th style='text-align:left'>th_placeholder1</th>
                <td>td_placeholder1</td>
            </tr>
            <tr id='placeholder2' style='visibility:hidden'>
                <th style='text-align:left'>th_placeholder2</th>
                <td>td_placeholder2</td>
            </tr>
            <tr id='placeholder3' style='visibility:hidden'>
                <th style='text-align:left'>th_placeholder3</th>
                <td>td_placeholder3</td>
            </tr>
            <tr id='placeholder4' style='visibility:hidden'>
                <th style='text-align:left'>th_placeholder4</th>
                <td>td_placeholder4</td>
            </tr>
            <tr id='placeholder5' style='visibility:hidden'>
                <th style='text-align:left'>th_placeholder5</th>
                <td>td_placeholder5</td>
            </tr>
            <tr id='placeholder6' style='visibility:hidden'>
                <th style='text-align:left'>th_placeholder6</th>
                <td>td_placeholder6</td>
            </tr>
        </table>
        <br><br>
        <span>$log</span>"

"<html><head><title>$BuildDefinitionName - Build:$BuildNumber</title></head>$body<body></body></html>" | Out-File $UploadFileName