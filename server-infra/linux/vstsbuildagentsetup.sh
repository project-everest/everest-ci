#!/bin/bash

# This script is responsible to do the complete setup in order to have build agents running on the linux build machine.

vstsPat=$1
poolName=${2:-MsrEverestPoolLinux}
initialPoolIndex=${3:-1}
finalPoolIndex=${3:-8}

if [ -z "$1" ]; then
    echo "VSTS Personal Access Token was not provided."
    exit
fi

Setup ()
{
    sudo bash ./bootstrap.sh $USER

    # Check if we have the agents folder, create it if needed.
    if ! [ -d /home/builder/build/agents ]; then
        mkdir -p /home/builder/build/agents
    fi

    if ! [ -d /home/builder/build/agents ]; then
        echo "Unable to create /home/builder/build/agents directory"
        exit
    fi

    # Download VSTS linux agent
    cd /home/builder/build/agents
    curl -O https://vstsagentpackage.azureedge.net/agent/2.131.0/vsts-agent-linux-x64-2.131.0.tar.gz

    for i in $(seq $initialPoolIndex $finalPoolIndex)
    do
        # Create agent directories if directory does not exist
        agentNumber="agent-$i"
        if ! [ -d $agentNumber ]; then
            # copy agent file to directory, if required and extract it.
            mkdir $agentNumber

            cp  vsts-agent-linux-x64-2.131.0.tar.gz $agentNumber/vsts-agent-linux-x64-2.131.0.tar.gz
            cd $agentNumber

            # extract files.
            tar zxvf vsts-agent-linux-x64-2.131.0.tar.gz

            # compressed file.
            rm vsts-agent-linux-x64-2.131.0.tar.gz
            cd ..
        fi

        # make directory accessible so we can run config script later.
        sudo chmod 777 $agentNumber

        agentNumber="agent-ondemand-$i"
        if ! [ -d $agentNumber ]; then
            # copy agent file to directory, if required and extract it.
            mkdir $agentNumber

            cp  vsts-agent-linux-x64-2.131.0.tar.gz $agentNumber/vsts-agent-linux-x64-2.131.0.tar.gz
            cd $agentNumber

            # extract files.
            tar zxvf vsts-agent-linux-x64-2.131.0.tar.gz

            # compressed file.
            rm vsts-agent-linux-x64-2.131.0.tar.gz
            cd ..
        fi

        # make directory accessible so we can run config script later.
        sudo chmod 777 $agentNumber
    done

    # Remove linux agent file.
    rm vsts-agent-linux-x64-2.131.0.tar.gz

    for i in $(seq 1 $numberOfAgents)
    do
        agentNumber="agent-$i"
        bash ./removeagents.sh $vstsPat $agentNumber
        bash ./configagents.sh $vstsPat $agentNumber
        sudo bash ./startagents.sh $vstsPat $agentNumber

        agentNumber="agent-ondemand-$i"
        bash ./removeagents.sh $vstsPat $agentNumber
        bash ./configagents.sh $vstsPat $agentNumber
        sudo bash ./startagents.sh $vstsPat $agentNumber
    done
}

Setup

echo "Done with setup."