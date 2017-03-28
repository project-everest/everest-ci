FROM projecteverest/everest-chomolungma-d8
LABEL maintainer "Irina Spiridonova <irinasp@microsoft.com>; Darren Gehring <darrenge@microsoft.com>; Tahina Ramananandro <taramana@microsoft.com>"

#Following variables should be provided while creating new Linux container: 
#PAT=<VSTS token>
#PAT_SLACK=<slack token>
#agent=<name of one of the existing agents>; Example: agent=Everest-CI-2
#Here is the example of the docker run command: docker run -it --name <container name> -e PAT=<VSTS token> -e PAT_SLACK=<slack token> -e agent=<agent name> --restart unless-stopped

#id_rsa and id_rsa.pub files are expected to be in the same directory as dockerfile

USER everest
WORKDIR ${MYHOME}

ENV CI_LOGS ${MYHOME}/ci-logs/

# Install Coq
ENV coqv 8.6
RUN opam repo add coq-released http://coq.inria.fr/opam/released
RUN opam install -j 8 coq.${coqv} && opam pin add coq ${coqv}

# Install CompCert
ENV compcertv 3.0.1
RUN wget -O compcert.tgz http://compcert.inria.fr/release/compcert-${compcertv}.tgz
RUN tar xf compcert.tgz
WORKDIR CompCert-${compcertv}
RUN ./configure x86_64-linux
RUN make -j 8
ENV PATH ${MYHOME}/CompCert-${compcertv}:$PATH

WORKDIR ${MYHOME}

#software-properties-common package is needed for add-apt-repository
#installing latest version of git and other packages
RUN sudo apt-get install --yes software-properties-common
RUN sudo add-apt-repository ppa:git-core/ppa
RUN sudo apt-get update
RUN sudo apt-get install --yes \
  git \
  nuget \
  openssh-client

#copying the keys, elevating permissions and changing the owner for the keys
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

#Prepare everest-ci and ci-logs repositories
WORKDIR ${MYHOME}
RUN git clone git@github.com:project-everest/everest-ci
RUN git clone git@github.com:project-everest/ci-logs
RUN git config --global user.email "everbld@microsoft.com"
RUN git config --global user.name "Dzomo the everest Yak"

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
