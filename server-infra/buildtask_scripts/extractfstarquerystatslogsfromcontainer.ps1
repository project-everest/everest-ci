# This script will extract FStar query stats log files from Container

param
(
    [Parameter(Mandatory=$true)]
    [String] $ContainerImageName,
    [Parameter(Mandatory=$true)]
    [String] $BuildRequestedAuthor
)

# Start container
docker run -t -d --name $BuildRequestedAuthor $ContainerImageName

# Copy buildlog file.
if ($Env:OS -eq "Windows_NT") {
docker exec $BuildRequestedAuthor cmd.exe /c type log_no_replay.html > log_no_replay.html
docker exec $BuildRequestedAuthor cmd.exe /c type log_worst.html > log_worst.html
} else {
docker exec $BuildRequestedAuthor cat log_no_replay.html > log_no_replay.html
docker exec $BuildRequestedAuthor cat log_worst.html > log_worst.html
}

# Stop Container
docker stop $BuildRequestedAuthor

# remove container
docker rm $BuildRequestedAuthor