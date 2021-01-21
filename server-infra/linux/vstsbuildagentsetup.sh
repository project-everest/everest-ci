#!/bin/bash

# This script is responsible to do the complete setup in order to have build agents running on the linux build machine.

vstsPat=$1
poolName=${2:-Msr-EverestPool-Linux}
poolNameOndemand=$(echo $poolName)-ondemand
initialPoolIndex=${3:-1}
finalPoolIndex=${3:-8}

echo PoolName = $poolName
echo PoolNameOnDemand = $poolNameOndemand
echo InitialPoolIndex = $initialPoolIndex
echo FinalPoolIndex = $finalPoolIndex

if [ -z "$1" ]; then
    echo "VSTS Personal Access Token was not provided."
    exit
fi

ConfigAgents ()
{
    local vstsPat=$1
    local poolName=$2
    local agentName=$3
    local remove=$4

    echo /home/builder/build/agents/$agentName

    if [ "$remove" = true ]; then
        if [ -d /home/builder/build/agents/$agentName ]; then
            echo Remove $agentName on $poolName
            cd /home/builder/build/agents/$agentName

            # Remove agents from a previous agent setup.
            sudo bash ./svc.sh stop >1
            sudo bash ./svc.sh uninstall >1
            bash ./config.sh remove --auth pat --token $vstsPat
        fi
    else
        echo Install $agentName on $poolName
        cd /home/builder/build/agents/$agentName

        # Now we setup the new agent.
        bash ./config.sh --unattended --url https://msr-project-everest.visualstudio.com --auth pat --token $vstsPat --pool $poolName --agent $agentName --acceptTeeEula

        sudo bash ./svc.sh install >1
        sudo bash ./svc.sh start >1
    fi
}

vsts_agent_version=2.181.0

Setup ()
{
    sudo bash ./bootstrap.sh $USER

    # Download VSTS linux agent
    cd /home/builder/build/agents
    sudo curl -O https://vstsagentpackage.azureedge.net/agent/$vsts_agent_version/vsts-agent-linux-x64-$vsts_agent_version.tar.gz

    for i in $(seq $initialPoolIndex $finalPoolIndex)
    do
        # Create agent directories if directory does not exist
        agentNumber="agent-$i"
        if ! [ -d $agentNumber ]; then
            # copy agent file to directory, if required and extract it.
            sudo mkdir $agentNumber

            sudo cp  vsts-agent-linux-x64-$vsts_agent_version.tar.gz $agentNumber/vsts-agent-linux-x64-$vsts_agent_version.tar.gz
            cd $agentNumber

            # extract files.
            sudo tar zxvf vsts-agent-linux-x64-$vsts_agent_version.tar.gz

            # compressed file.
            sudo rm vsts-agent-linux-x64-$vsts_agent_version.tar.gz
            cd ..
        fi

        # make directory accessible so we can run config script later.
        sudo chmod 777 $agentNumber

        agentNumber="agent-ondemand-$i"
        if ! [ -d $agentNumber ]; then
            # copy agent file to directory, if required and extract it.
            sudo mkdir $agentNumber

            sudo cp  vsts-agent-linux-x64-$vsts_agent_version.tar.gz $agentNumber/vsts-agent-linux-x64-$vsts_agent_version.tar.gz
            cd $agentNumber

            # extract files.
            sudo tar zxvf vsts-agent-linux-x64-$vsts_agent_version.tar.gz

            # compressed file.
            sudo rm vsts-agent-linux-x64-$vsts_agent_version.tar.gz
            cd ..
        fi

        # make directory accessible so we can run config script later.
        sudo chmod 777 $agentNumber
    done

    # Remove linux agent file.
    sudo rm vsts-agent-linux-x64-$vsts_agent_version.tar.gz

    for i in $(seq $initialPoolIndex $finalPoolIndex)
    do
        agentName="agent-$i"
        ConfigAgents $vstsPat $poolName $agentName true
        ConfigAgents $vstsPat $poolName $agentName false

        agentName="agent-ondemand-$i"
        ConfigAgents $vstsPat $poolNameOndemand $agentName true
        ConfigAgents $vstsPat $poolNameOndemand $agentName false
    done
}

Setup

echo "Done with setup."
