#!/bin/bash

# This script is responsible to start the linux build agents as services.

vstsPat=$1
agentNumber=$2

StartAgents () 
{
    cd /home/everest/build/agents/$agentNumber

    bash ./svc.sh install >1
    bash ./svc.sh start >1
}

StartAgents

echo "Done starting agents."