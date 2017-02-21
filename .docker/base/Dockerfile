FROM projecteverest/everest-chomolungma-d8
LABEL maintainer "Irina Spiridonova <irinasp@microsoft.com>; Darren Gehring <darrenge@microsoft.com>; Tahina Ramananandro <taramana@microsoft.com>"

USER everest
WORKDIR ${MYHOME}

#PAT token should be provided in the docker run command or as a variable in VSTS build definition 
ENV PAT $PAT

#software-properties-common package is needed for add-apt-repository
#installing latest version of git
RUN sudo apt-get install --yes software-properties-common
RUN sudo add-apt-repository ppa:git-core/ppa
RUN sudo apt-get update
RUN sudo apt-get install git nuget

#Prepare everest-ci and everest-logs repositories
RUN git clone https://$PAT@github.com/project-everest/everest-ci.git
RUN git clone https://$PAT@github.com/project-everest/ci-logs.git
RUN echo "export CI_LOGS=/$MYHOME/everest/ci-logs/" >> .bashrc 
RUN . $MYHOME/.bashrc

#Prepare vsts agent
RUN mkdir vsts-agent
WORKDIR $MYHOME/vsts-agent
RUN wget https://github.com/Microsoft/vsts-agent/releases/download/v2.111.1/vsts-agent-ubuntu.16.04-x64-2.111.1.tar.gz
RUN tar zxvf ~/vsts-agent/vsts-agent-ubuntu.16.04-x64-2.111.1.tar.gz 

#Add environment variables for slack notification
#RUN echo "export SLACK_FSTAR_WEBHOOK=https://hooks.slack.com/services/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" >> .bashrc

WORKDIR ${MYHOME}
#Run the script to deploy and start vsts agent 
#ADD start-agent.sh $MYHOME/start-agent.sh
ENTRYPOINT $MYHOME/everest-ci/.docker/base/start-agent.sh

