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
docker exec $BuildRequestedAuthor$CommitId cat log_no_replay.html > log_no_replay.html
docker exec $BuildRequestedAuthor$CommitId cat log_worst.html > log_worst.html

# Stop Container
docker stop $BuildRequestedAuthor$CommitId

# remove container
docker rm $BuildRequestedAuthor$CommitId