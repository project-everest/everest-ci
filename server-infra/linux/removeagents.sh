#!/bin/bash

# This script is responsible to remove all linux build agents.

vstsPat=$1
agentNumber=$2

RemoveAgents () 
{
    if [ -d /home/everest/build/agents/$agentNumber ]; then
        cd /home/everest/build/agents/$agentNumber

        # Remove agents from a previous agent setup.
        sudo bash ./svc.sh stop >1
        sudo bash ./svc.sh uninstall >1
        bash ./config.sh remove --auth pat --token $vstsPat
    fi
}

RemoveAgents

echo "Done removing agents."