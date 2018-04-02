#!/bin/bash

# This script is responsible to setup the linux build agents.

vstsPat=$1
agentNumber=$2

ConfigAgents () 
{
    cd /home/everest/build/agents/$agentNumber

    # Now we setup the new agent.
    bash ./config.sh --unattended --url https://msr-everest.visualstudio.com --auth pat --token $vstsPat --pool MsrEverestPoolLinux --agent $agentNumber --acceptTeeEula
}

ConfigAgents

echo "Done configuring agents."