#!/bin/bash
#Prepare everest-ci and everest-logs repositories; adding environment variable
#VSTS PAT token, slack token and agent name variables should be provided in the docker run command

cd $MYHOME
#Add environment variable for slack notifications
export SLACK_FSTAR_WEBHOOK=https://hooks.slack.com/services/${PAT_SLACK}
echo "export SLACK_FSTAR_WEBHOOK=$SLACK_FSTAR_WEBHOOK" >> ${MYHOME}/.profile
cd $MYHOME/vsts-agent

#variables for configuring vsts agent
url="https://msresearch-ext.visualstudio.com"
pool="Everest Linux Pool"

#copied config.sh file here to workaround 'the quotes around argument with space' removal
#below command doesn't work because pool argument has spaces which are removed while passing it to Agent.Listener command in the config.sh script
#./config.sh --unattended --url "$url" --token $PAT --pool "$pool" --agent "$agent" --replace 
user_id="`id -u`"
# we want to snapshot the environment of the config user
if [ "$user_id" -eq 0 ]; then
    echo "Must not run with sudo"
    exit 1
fi
#configure agent
./bin/Agent.Listener configure --unattended --url "$url" --token "$PAT" --pool "$pool" --agent "$agent" --replace

#connecting to server and start listening for job
./run.sh