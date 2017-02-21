#!/bin/bash
cd $MYHOME/vsts-agent

#variables for configuring vsts agent
url="https://msresearch-ext.visualstudio.com"
pool="Everest Linux Pool"
agent="Everest-CI-3"

#copied config.sh file here to workaround 'the quotes around argument with space' removal
#below command doesn't work because pool argument has spaces which are removed while passing it to Agent.Listener command in the config.sh script
#./config.sh --unattended --url "$url" --token $PAT --pool "$pool" --agent "$agent" --replace 
user_id="id -u"
# we want to snapshot the environment of the config user
if [ ${user_id} -eq 0 ]; then
    echo "Must not run with sudo"
    exit 1
fi
source ./env.sh

./bin/Agent.Listener configure --unattended --url "$url" --token "$PAT" --pool "$pool" --agent "$agent" --replace

#connecting to server and start listening for job
./run.sh