#!/bin/bash

# This script is responsible to do the complete setup in order to have build agents running on the linux build machine.

vstsPat=$1
poolName=${2:-MsrEverestPoolLinux}
poolNameOndemand=$poolName-ondemand
initialPoolIndex=${3:-1}
finalPoolIndex=${3:-8}

if [ -z "$1" ]; then
    echo "VSTS Personal Access Token was not provided."
    exit
fi

ConfigAgents ()
{
    vstsPat=$1
    poolName=$2
    agentFolder=$3
    agentNumber=$4
    remove=$5

    if [ "$remove" = true ]; then
        if [ -d /home/builder/build/agents/$agentFolder ]; then
            cd /home/builder/build/agents/$agentFolder

            # Remove agents from a previous agent setup.
            sudo bash ./svc.sh stop >1
            sudo bash ./svc.sh uninstall >1
            bash ./config.sh remove --auth pat --token $vstsPat
        fi
    else
        cd /home/builder/build/agents/$agentFolder

        # Now we setup the new agent.
        bash ./config.sh --unattended --url https://msr-project-everest.visualstudio.com --auth pat --token $vstsPat --pool $poolName --agent $agentNumber --acceptTeeEula

        sudo bash ./svc.sh install >1
        sudo bash ./svc.sh start >1
    fi
}

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
    curl -O https://vstsagentpackage.azureedge.net/agent/2.140.0/vsts-agent-osx-x64-2.140.0.tar.gz

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

    for i in $(seq $initialPoolIndex $finalPoolIndex)
    do
        agentNumber="agent-$i"
        ConfigAgents $vstsPat $poolName $agentNumber $agentNumber true
        ConfigAgents $vstsPat $poolName $agentNumber $agentNumber false

        agentFolder="agent-ondemand-$i"
        ConfigAgents $vstsPat $poolNameOndemand $agentFolder $agentNumber true
        ConfigAgents $vstsPat $poolNameOndemand $agentFolder $agentNumber false
    done
}

Setup

echo "Done with setup."