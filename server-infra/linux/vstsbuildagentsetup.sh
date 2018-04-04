#!/bin/bash

# This script is responsible to do the complete setup in order to have build agents running on the linux build machine.

vstsPat=$1

Setup () 
{
    numberOfAgents=8
    sudo bash ./bootstrap.sh $numberOfAgents

    for i in $(seq 1 $numberOfAgents)
    do
        agentNumber="agent-$i"
        bash ./removeagents.sh $vstsPat $agentNumber
        bash ./configagents.sh $vstsPat $agentNumber
        sudo bash ./startagents.sh $vstsPat $agentNumber
    done
}

Setup

echo "Done with setup."