FROM projecteverest/everest-chomolungma-d8
LABEL maintainer "Irina Spiridonova <irinasp@microsoft.com>; Darren Gehring <darrenge@microsoft.com>; Tahina Ramananandro <taramana@microsoft.com>"

USER everest
WORKDIR ${MYHOME}

ENV CI_LOGS ${MYHOME}"/ci-logs/"

#PAT token and agent name should be provided in the docker run command when docker container is started 

#software-properties-common package is needed for add-apt-repository
#installing latest version of git and other packages
RUN sudo apt-get install --yes software-properties-common
RUN sudo add-apt-repository ppa:git-core/ppa
RUN sudo apt-get update
RUN sudo apt-get install --yes \
  git \
  nuget \
  openssh-client

#copying the keys, elevating permissions and changing the key's owner for the key
WORKDIR ${MYHOME}
USER everest
RUN mkdir -p ${MYHOME}/.ssh
RUN chown everest ${MYHOME}/.ssh
RUN chmod 700 ${MYHOME}/.ssh
ADD id_rsa ${MYHOME}/.ssh/id_rsa
ADD id_rsa.pub ${MYHOME}/.ssh/id_rsa.pub
RUN sudo chmod 600 ${MYHOME}/.ssh/id_rsa; sudo chmod 600 ${MYHOME}/.ssh/id_rsa.pub 
RUN sudo chown everest ${MYHOME}/.ssh/id_rsa; sudo chown everest ${MYHOME}/.ssh/id_rsa.pub

#Workaround for cloning a repo in a non-interactive way
RUN echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ${MYHOME}/.ssh/config

#Prepare everest-ci and ci-logs repositories, calling add-repo.sh script
ADD add-repo.sh ${MYHOME}/add-repo.sh
RUN ./add-repo.sh

#Prepare vsts agent
ENV agentv v2.111.1
ENV agentplatform vsts-agent-ubuntu.16.04-x64-2.111.1
RUN mkdir vsts-agent
WORKDIR ${MYHOME}/vsts-agent
RUN wget https://github.com/Microsoft/vsts-agent/releases/download/${agentv}/${agentplatform}.tar.gz
RUN tar zxvf ${agentplatform}.tar.gz 

WORKDIR ${MYHOME}
#Run the script to deploy and start vsts agent 
ADD start-agent.sh ${MYHOME}/start-agent.sh
ENTRYPOINT ${MYHOME}/start-agent.sh
