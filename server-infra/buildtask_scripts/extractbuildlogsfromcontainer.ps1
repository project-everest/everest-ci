# This script will extract log files from Container

param
(
    [Parameter(Mandatory=$true)]
    [String] $ContainerImageName,
    [Parameter(Mandatory=$true)]
    [String] $BuildRequestedAuthor,
    [Parameter(Mandatory=$true)]
    [String] $BuildLogFile
)

# Start container
docker run -t -d --name $BuildRequestedAuthor $ContainerImageName

# Copy buildlog file.
docker exec $BuildRequestedAuthor cat $BuildLogFile >$BuildLogFile

# Stop Container
docker stop $BuildRequestedAuthor

# remove container
docker rm $BuildRequestedAuthor