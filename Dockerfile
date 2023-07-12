#
# Aerospike Sandbox Jupyter Dockerfile
#

FROM jupyter/base-notebook:python-3.8.6 as build

USER root

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100

ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    AEROSPIKE_VERSION=6.2.0.12 \
    LOGFILE=/var/log/aerospike/aerospike.log \
    GO_VERSION=1.20.4 \
    GOROOT=/usr/local/go \
    NODE_VERSION=18.16.1 \
    NVM_DIR=/usr/local/.nvm
ENV HOME=/home/${NB_USER}
ENV GOPATH=${HOME}/go \
    DOTNET_ROOT=${HOME}/dotnet
ENV PATH=$PATH:/usr/local/go/bin:${GOROOT}/bin:${GOPATH}/bin:${HOME}/dotnet:${HOME}/.dotnet/tools:/root/.nvm/versions/node/v${NODE_VERSION}/bin/

# setup
RUN mkdir -p /var/log/aerospike /var/run/aerospike /backup /aerospike /usr/local/.nvm ${HOME}/dotnet && \
    apt-get update -y && \
    apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 && \
    apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' && \
    apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python3-pip python3-dev python3 zulu-11 && \
    apt-get purge -y && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*
    
# install aerospike
RUN wget "https://artifacts.aerospike.com/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-8.1.0_ubuntu20.04_x86_64.tgz" -O aerospike-server.tgz && \  
    tar xzf aerospike-server.tgz --strip-components=1 -C /aerospike && \
    dpkg -i /aerospike/aerospike-server-*.deb && \
    dpkg -i /aerospike/aerospike-tools_*.deb && \
    usermod -a -G aerospike ${NB_USER} && \
    python3 -m pip install --no-cache-dir aerospike && \
    rm -rf aerospike-server.tgz /aerospike /var/lib/apt/lists/*

# install Java
RUN wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip && \
    unzip ijava-kernel.zip -d ijava-kernel && \
    python3 ijava-kernel/install.py --sys-prefix && \
    rm ijava-kernel.zip 

#install Go
RUN wget -O go.tgz https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go.tgz && \
    rm go.tgz && \
    go install github.com/janpfeifer/gonb@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install golang.org/x/tools/gopls@latest && \
    gonb --install

#install node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION} && \
    npm install aerospike@5.0.3 && \
    npm install -g --unsafe-perm ijavascript && \
    ijsinstall --spec-path=full --working-dir=${HOME}

#install .NET
RUN wget -O dotnet.tgz https://download.visualstudio.microsoft.com/download/pr/351400ef-f2e6-4ee7-9d1b-4c246231a065/9f7826270fb36ada1bdb9e14bc8b5123/dotnet-sdk-7.0.302-linux-x64.tar.gz && \
    tar zxf dotnet.tgz -C ${HOME}/dotnet && \
    rm -rf dotnet.tgz && \
    dotnet tool install --global Microsoft.dotnet-interactive && \
    dotnet-interactive jupyter install && \
    rm /tmp/NuGetScratch/lock/*

COPY sandbox_00000.asb /backup/sandbox.asb
COPY start-asd.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/start-notebook.sh
COPY spaceCompanies.json /backup/
COPY example.lua /home/user/udf/
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf
COPY .bashrc /home/${NB_USER}/.bashrc

RUN chown -R ${NB_UID} ${HOME} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike && \
    chmod +x /usr/local/bin/start-asd.sh && \
    fix-permissions /home/${NB_USER}/

FROM ubuntu:20.04 as final

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100

ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    CONDA_DIR=/opt/conda \
    AEROSPIKE_VERSION=6.2.0.12 \
    LOGFILE=/var/log/aerospike/aerospike.log \
    GO_VERSION=1.20.4 \
    GOROOT=/usr/local/go \
    NODE_VERSION=16.13.0 \
    SHELL=/bin/bash \
    JUPYTER_PORT=8888
ENV HOME=/home/${NB_USER}
ENV GOPATH=${HOME}/go \
    DOTNET_ROOT=${HOME}/dotnet
ENV PATH=$PATH:/usr/local/go/bin:${GOROOT}/bin:${GOPATH}/bin:${HOME}/dotnet:${HOME}/.dotnet/tools:/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${CONDA_DIR}/bin

USER root
WORKDIR /

# Load data
COPY --from=build . /

EXPOSE ${JUPYTER_PORT}

CMD ["start-notebook.sh"]

WORKDIR /home/${NB_USER}
USER ${NB_USER}

ENTRYPOINT ["tini", "-g", "--", "start-asd.sh"]
