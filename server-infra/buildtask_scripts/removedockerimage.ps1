# This script is responsible to delete the local docker image.

param
(
    [Parameter(Mandatory=$true)]
    [String] $ContainerImageName
)

#remove image
docker rmi $ContainerImageName -f