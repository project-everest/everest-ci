#!/bin/bash

# This script is responsible to setup the linux build machine.
# Run it if you need to setup or resetup the linux build server.

numberOfAgents=$1
serviceUser=$2

Bootstrap () 
{
    # This part of script should run as root/sudo.
    if [ $(/usr/bin/id -u) -ne 0 ]; then
        echo "Not running as root. Please re-run script as root."
        exit
    fi

    apt-get upgrade -y

    # Install some dependencies
    apt-get update -y

    # Rename machine name.
    # Server machine should be name as Everest-BuildServer-Linux
    servername=$(cat /etc/hostname)
    if [ $servername != "Everest-BuildServer-Linux" ]
    then
        echo "Everest-BuildServer-Linux" | sudo tee /etc/hostname
    fi

    # Verify dotnet is not installed.
    if ! command -v dotnet > /dev/null 2>&1; then

        apt-get install -y libunwind8
        apt-get install -y liblttng-ust0
        apt-get install -y libcurl3
        apt-get install -y libuuid1
        apt-get install -y libkrb5-3
        apt-get install -y zlib1g
        apt-get install -y curl 
        apt-get install -y gettext 
        apt-get install -y apt-transport-https
        apt-get install -y gnupg
        apt-get install -y ca-certificates
        apt-get install -y software-properties-common
        apt-get install -y dirmngr

        # Download script to install dotnet runtime
        echo "Download dotnet core install script."
        curl -O https://dot.net/v1/dotnet-install.sh
        chmod +x dotnet-install.sh
        ./dotnet-install.sh

        # Install System components and prepare instalation for Debian 9
        apt-get update -y

        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

        # Register the Microsoft Product feed
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list

        # Install dotnet core
        apt-get update -y
        apt-get install -y dotnet-sdk-2.0.0

        export PATH=$PATH:$HOME/dotnet

        # Verify dotnet was installed.
        if ! command -v dotnet > /dev/null 2>&1; then
            echo "Fail to install dotnet."
            exit
        fi

        # remove dotnet script file.
        rm dotnet-install.sh
    fi

    # Verify PowerShell is not installed.
    if ! command -v pwsh > /dev/null 2>&1; then
        # Install Powershell, this will enable us to have the build definition to directly manage containers on azure.
        # Import the public repository GPG keys
        curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

        # Update the list of products
        # Install PowerShell
        apt-get update -y
        apt-get install -y powershell

        # Verify PowerShell was installed.
        if ! command -v pwsh > /dev/null 2>&1; then
            echo "Fail to install powershell."
            exit
        fi

        # Install Azure Powerhsell module
        sudo pwsh -c "Install-Module AzureRM.NetCore -Force"
    fi

    # Verify Azure CLI is installed
    if ! command -v az > /dev/null 2>&1; then
        # Install Azure CLI
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli stretch main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
        apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
        apt-get update -y
        apt-get install azure-cli -y

         # Verify PowerShell was installed.
        if ! command -v az > /dev/null 2>&1; then
            echo "Fail to install Azure CLI."
            exit
        fi
    fi

    # Verify docker is not installed.
    if ! command -v docker > /dev/null 2>&1; then
        # Install Docker
        curl https://download.docker.com/linux/debian/gpg | apt-key add -
        apt-key fingerprint 0EBFCD88
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable"

        apt-get update -y
        apt-get install -y docker-ce

        # Verify PowerShell was installed.
        if ! command -v docker > /dev/null 2>&1; then
            echo "Fail to install docker."
            exit
        fi

        #Build our Everest base image
        docker build -f .docker/Dockerfile -t everest_base_image:1 .
    fi

    usermod -a -G docker $serviceUser

    # Check if we have the agents folder, create it if needed.
    if ! [ -d /home/everest/build/agents ]; then
        mkdir -p /home/everest/build/agents
    fi

    if ! [ -d /home/everest/build/agents ]; then
        echo "Unable to create /home/everest/build/agents directory"
        exit
    fi

    # Download VSTS linux agent
    cd /home/everest/build/agents
    curl -O https://vstsagentpackage.azureedge.net/agent/2.131.0/vsts-agent-linux-x64-2.131.0.tar.gz

    for i in $(seq 1 $numberOfAgents)
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
    done

    # Remove linux agent file.
    rm vsts-agent-linux-x64-2.131.0.tar.gz
}

Bootstrap

# Done
echo "Bootstrap done."