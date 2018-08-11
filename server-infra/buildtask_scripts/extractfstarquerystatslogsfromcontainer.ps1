# This script will extract FStar query stats log files from Container

param
(
    [Parameter(Mandatory=$true)]
    [String] $ContainerImageName,
    [Parameter(Mandatory=$true)]
    [String] $BuildRequestedAuthor,
    [Parameter(Mandatory=$true)]
    [String] $CommitId
)

# Start container
docker run -t -d --name $BuildRequestedAuthor$CommitId $ContainerImageName

# Copy buildlog file.
if ($Env:OS -eq "Windows_NT") {
    docker exec $BuildRequestedAuthor$CommitId cmd.exe /c type c:\ewerest\log_no_replay.html > log_no_replay.html
    docker exec $BuildRequestedAuthor$CommitId cmd.exe /c type c:\ewerest\log_worst.html > log_worst.html
} else {
    docker exec $BuildRequestedAuthor$CommitId cat log_no_replay.html > log_no_replay.html
    docker exec $BuildRequestedAuthor$CommitId cat log_worst.html > log_worst.html
}

# Stop Container
docker stop $BuildRequestedAuthor$CommitId

# remove container
docker rm $BuildRequestedAuthor$CommitId