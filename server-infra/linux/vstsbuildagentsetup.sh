#!/bin/bash

# This script is responsible to do the complete setup in order to have build agents running on the linux build machine.

vstsPat=$1

if [ -z "$1" ]; then
    echo "VSTS Personal Access Token was not provided."
    exit
fi

Setup ()
{
    numberOfAgents=8
    sudo bash ./bootstrap.sh $numberOfAgents $USER

    for i in $(seq 1 $numberOfAgents)
    do
        agentNumber="agent-$i"
        bash ./removeagents.sh $vstsPat $agentNumber
        bash ./configagents.sh $vstsPat $agentNumber
        sudo bash ./startagents.sh $vstsPat $agentNumber
    done

    if [[ "$(docker images -q everest_base_image:1 2> /dev/null)" == "" ]]; then
        #Build our Everest base image
        docker build -f .docker/Dockerfile -t everest_base_image:1 .
    fi
}

Setup

echo "Done with setup."