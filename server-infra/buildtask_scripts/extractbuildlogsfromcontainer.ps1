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
if ($Env:OS -eq "Windows_NT") {
docker exec $BuildRequestedAuthor cmd.exe /c type $BuildLogFile > $BuildLogFile
docker exec $BuildRequestedAuthor cmd.exe /c type "result.txt" > "result.txt"
} else {
docker exec $BuildRequestedAuthor cat $BuildLogFile > $BuildLogFile
docker exec $BuildRequestedAuthor cat "result.txt" > "result.txt"
}

# Stop Container
docker stop $BuildRequestedAuthor

# remove container
docker rm $BuildRequestedAuthor