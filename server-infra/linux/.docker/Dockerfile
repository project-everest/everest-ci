# This is the Everest Base Image
# Version 1
# If you make changes to this file, make sure to update the version above and rebuild the image, 
# also update all references to use the new version, this image should be built using:
# docker build -f Dockerfile -t everest_base_image:$V .
# Where $V is the number of the version above
FROM ubuntu:xenial

# Add a new mirror, maybe more stable than Docker's
RUN echo 'deb http://mirror.pnl.gov/ubuntu/ xenial main' >> /etc/apt/sources.list
RUN echo "deb http://mirror.math.ucdavis.edu/ubuntu/ xenial main" >> /etc/apt/sources.list

# Try to overcome the "Hash Sum Mismatch" failure by retrying if failed
RUN echo "Acquire::Retries \"16\";" > /etc/apt/apt.conf.d/99acquire-retries

# Commit changes
RUN apt-get --yes update

# Configure new PPA for gcc-6
RUN apt-get install --no-install-recommends --yes software-properties-common curl
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get --yes update

# Configure repository for node.js 6.x LTS
# from: https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -

# Here start the Everest-specific packages.
RUN until apt-get install --no-install-recommends --yes \
        libssl-dev \
		libsqlite3-dev \
		g++-6 \
		gcc-6 \ 
		m4 \
		make \
		opam \
		git \
		pandoc \
		pkg-config \
		python \
		libgmp3-dev \
		unzip \
		build-essential \
		automake \
		ca-certificates-mono \
		fsharp \
		libunwind8 \
		libcurl3 \
		scons \
		sudo \
		python3 \
		nuget \
		ca-certificates \
		cmake \
		libtool \
		autoconf \
		tzdata \
		openssh-server \
		vim \
		curl \
		wget \
		tcptraceroute \
		emacs \
		; do apt-get --yes update ; done

#Install node.js
RUN curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
RUN apt-get install -y nodejs

#install typescript
RUN npm install -g typescript

#install less
RUN npm install -g less

# Install madoko
RUN npm install madoko -g

# Setup ssh
RUN mkdir /var/run/sshd

# Set root password
RUN echo root:Docker! | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# start service
RUN service ssh start

# Create user everest.
# We define a home directory by ourselves, because there is no way to have the HOME variable caught by WORKDIR.
# So, to make it consistent, we explicitly make this directory home when creating the user.
ENV MYHOME /home/everest
RUN useradd --shell /bin/bash --create-home --home-dir ${MYHOME} everest
RUN echo "everest ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo everest:Docker! | chpasswd

# --login: Ensure that the .profile is read at each subsequent RUN (to take all the settings and environment that opam will write there).
# Other options to bash may be added here, but -c MUST BE the last one (it introduces the actual command to be RUN)
SHELL ["/bin/bash", "--login", "-c"]

# Switch to user mode 
USER everest 
WORKDIR ${MYHOME}

# Prepare build (OCaml packages)
ENV opamv 4.05.0
ENV OPAMYES true
RUN opam init --auto-setup --comp ${opamv} --yes

# Prepare Everest; we write the everest-specific settings into the GLOBAL
# /etc/profile so that all users benefit from them. Note: had to modify
# init_container.sh so that its dumb writeout of the entire environment goes
# before our customizations.
RUN git clone https://github.com/project-everest/everest.git
RUN rm -rf .git
ENV EVEREST_ENV_DEST_FILE ${MYHOME}/.profile
RUN ./everest/everest --yes check
RUN  eval $(opam config env)

EXPOSE 22 80

# Set the final directory entrypoint
WORKDIR ${MYHOME}/everest

ADD ./start_container /start_container
RUN sudo chmod +x /start_container
CMD ["/start_container"]