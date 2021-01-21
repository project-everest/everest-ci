#!/bin/bash

# This script is responsible to setup the linux build machine.
# Run it if you need to setup or resetup the linux build server.

serviceUser=$1

Bootstrap ()
{
    # This part of script should run as root/sudo.
    if [ $(/usr/bin/id -u) -ne 0 ]; then
        echo "Not running as root. Please re-run script as root."
        exit
    fi

    # Globally disable password prompts on sudo
    if ! [ -f /etc/sudoers.d/nopasswd ] ; then
        echo '%sudo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd
        chmod 0440 /etc/sudoers.d/nopasswd
    fi

    # Disable SSH password authentication
    local must_restart_ssh=false
    if ! grep '^ *PasswordAuthentication \+no' /etc/ssh/sshd_config ; then
        echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
        must_restart_ssh=true
    fi

    if $must_restart_ssh ; then
        service sshd restart
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

    # Check if we have build folder, create it if needed.
    if ! [ -d /home/build/build ]; then
        mkdir -p /home/builder/build
    fi

    if ! [ -d /home/builder/build ]; then
        echo "Unable to create /home/builder/build directory"
        exit
    fi

    cd /home/builder/build

    # Verify dotnet is not installed.
    if ! command -v dotnet > /dev/null 2>&1; then

        apt-get install -y libunwind8
        apt-get install -y liblttng-ust0
        apt-get install -y libcurl3
        apt-get install -y libicu-dev
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
        ./dotnet-install.sh -c Current

        # Install System components and prepare instalation for Debian 9
        apt-get update -y

        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

        wget -q https://packages.microsoft.com/config/debian/9/prod.list
        mv prod.list /etc/apt/sources.list.d/microsoft-prod.list

        chown root:root /etc/apt/trusted.gpg.d/microsoft.gpg
        chown root:root /etc/apt/sources.list.d/microsoft-prod.list

        apt-get update -y

        # Register the Microsoft Product feed
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list

        # Install dotnet core
        apt-get update -y
        apt-get install -y dotnet-sdk-2.1

        export PATH=$PATH:$HOME/dotnet

        # Verify dotnet was installed.
        if ! command -v dotnet > /dev/null 2>&1; then
            echo "Fail to install dotnet."
            exit
        fi

        # remove dotnet script file.
        rm dotnet-install.sh

        #Install node.js
        curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
        apt-get install -y nodejs

        #install typescript
        npm install -g typescript
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
        # From https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

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

        usermod -a -G docker $serviceUser

        # Restart machine to take any effect that requires a restart.
        echo "Restarting machine, please re-run script once it is back."
        sleep 5
        sudo shutdown -r 0
    fi

    # Check if we have the agents folder, create it if needed.
    if ! [ -d /home/builder/build/agents ]; then
        mkdir -p /home/builder/build/agents
    fi

    if ! [ -d /home/builder/build/agents ]; then
        echo "Unable to create /home/builder/build/agents directory"
        exit
    fi
}

Bootstrap

# Done
echo "Bootstrap done."
