#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#
# This docker file is compatible with Aerospike Community Edition. It provides Java and Python environments and access to the Aerospike DB.
FROM jupyter/base-notebook:python-3.8.6

USER root

ENV AEROSPIKE_VERSION 5.7.0.8
ENV AEROSPIKE_SHA256 e8ca3b53348a627974ca35ea9ff4c8975e4d0eb44222ddca947faede9f543928
ENV LOGFILE /var/log/aerospike/aerospike.log
ENV PATH=$PATH:/usr/local/go/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root
RUN chown -R ${NB_UID} ${HOME}

RUN mkdir /var/run/aerospike\
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python python3-pip python3-dev python3 zulu-11 \
  && wget "https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise-${AEROSPIKE_VERSION}-ubuntu20.04.tgz" -O aerospike-server.tgz \  
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && pip install --no-cache-dir aerospike\
  && pip install --no-cache-dir pymongo\
  && wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip\
  && unzip ijava-kernel.zip -d ijava-kernel \
  && python3 ijava-kernel/install.py --sys-prefix\
  && rm ijava-kernel.zip\
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y \
  && mkdir -p /var/log/aerospike  

#install Go
RUN wget -O go.tgz https://golang.org/dl/go1.18.3.linux-amd64.tar.gz \
  && tar -C /usr/local -xzf go.tgz \
  && rm go.tgz \
  && go install github.com/gopherdata/gophernotes@v0.7.5 \
  && mkdir -p ~/.local/share/jupyter/kernels/gophernotes \
  && cd ~/.local/share/jupyter/kernels/gophernotes \
  && cp $(go env GOPATH)/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/* "." \
  && sed "s_gophernotes_$(go env GOPATH)/bin/gophernotes_" <kernel.json.in >kernel.json \
  && cd $(go env GOPATH)/pkg/mod/github.com/go-zeromq/zmq4@v0.14.1 \
  && go get -u \
  && go mod tidy \
  && cd $(go env GOPATH)/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5 \  
  && go get -u \
  && go mod tidy
  
#install node.js
ENV NODE_VERSION=16.13.0
RUN mkdir /usr/local/.nvm
ENV NVM_DIR=/usr/local/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION} \
  && npm install aerospike \
  && npm install -g --unsafe-perm zeromq \
  && npm install -g --unsafe-perm ijavascript \
  && ijsinstall --spec-path=full --working-dir=${HOME}

ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"  

#install .NET
ENV DOTNET_ROOT=${HOME}/dotnet
ENV PATH=$PATH:${HOME}/dotnet
ENV PATH=$PATH:${HOME}/.dotnet/tools
RUN wget https://download.visualstudio.microsoft.com/download/pr/dc930bff-ef3d-4f6f-8799-6eb60390f5b4/1efee2a8ea0180c94aff8f15eb3af981/dotnet-sdk-6.0.300-linux-x64.tar.gz \
  && mkdir -p ${HOME}/dotnet && tar zxf dotnet-sdk-6.0.300-linux-x64.tar.gz -C ${HOME}/dotnet \
  && rm -rf dotnet-sdk-6.0.300-linux-x64.tar.gz \
  && dotnet tool install --global Microsoft.dotnet-interactive \
  && dotnet-interactive jupyter install \
  && rm /tmp/NuGetScratch/lock/*

COPY aerospike /etc/init.d/
RUN usermod -a -G aerospike ${NB_USER}

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf

RUN chown -R ${NB_UID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike

# Load data
RUN mkdir /backup
COPY sandbox_00000.asb /backup/sandbox.asb 
COPY .bashrc /home/${NB_USER}/
COPY start.sh /home/${NB_USER}/
COPY jupyter_notebook_config.py /home/${NB_USER}/

RUN fix-permissions /home/${NB_USER}/

# I don't know why this has to be like this 
# rather than overiding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh
#I had to do this to get the container to launch, not sure what I was doing wrong
RUN chmod +x /usr/local/bin/start-notebook.sh
WORKDIR /home/${NB_USER}
USER ${NB_USER}
