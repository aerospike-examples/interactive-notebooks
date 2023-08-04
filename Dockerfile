#
# Aerospike Sandbox Jupyter Dockerfile
#

FROM ubuntu:20.04 as build

USER root
    
ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100
ARG NODE_VERSION=18.x
ARG GO_VERSION=1.20.4
ARG AEROSPIKE_VERSION=6.4.0.0

ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LOGFILE=/var/log/aerospike/aerospike.log \
    GOROOT=/usr/local/go    
ENV HOME=/home/${NB_USER}
ENV GOPATH=${HOME}/go \
    DOTNET_ROOT=${HOME}/dotnet
ENV PATH=$PATH:/usr/local/go/bin:${GOROOT}/bin:${GOPATH}/bin:${HOME}/dotnet:${HOME}/.dotnet/tools

RUN useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}"

WORKDIR /home/${NB_USER}

# setup
RUN mkdir -p /var/log/aerospike /var/run/aerospike /backup /aerospike ${HOME}/dotnet && \
    apt-get update -y && \
    apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 && \
    apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' && \
    apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python3-pip python3-dev python3 zulu-11 && \
    apt-get purge -y && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*
    
# install Aerospike
RUN wget "https://download.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-9.0.0_ubuntu20.04_x86_64.tgz" -O aerospike-server.tgz && \  
    tar xzf aerospike-server.tgz --strip-components=1 -C /aerospike && \
    dpkg -i /aerospike/aerospike-server-*.deb && \
    dpkg -i /aerospike/aerospike-tools_*.deb && \
    usermod -a -G aerospike ${NB_USER} && \
    python3 -m pip install --no-cache-dir aerospike jupyterlab notebook && \
    rm -rf aerospike-server.tgz /aerospike /var/lib/apt/lists/*

# install Java kernel
RUN wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip && \
    unzip ijava-kernel.zip -d ijava-kernel && \
    python3 ijava-kernel/install.py --sys-prefix && \
    rm ijava-kernel.zip 

#install Go kernel
RUN wget -O go.tgz https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go.tgz && \
    rm go.tgz && \
    go install github.com/janpfeifer/gonb@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install golang.org/x/tools/gopls@latest && \
    gonb --install

#install Node.js kernel
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - &&\
    apt-get install -y nodejs && \
    npm install aerospike && \
    npm install -g --unsafe-perm ijavascript && \
    ijsinstall --spec-path=full --working-dir=${HOME}

#install .NET kernel
RUN wget -O dotnet.tgz https://download.visualstudio.microsoft.com/download/pr/351400ef-f2e6-4ee7-9d1b-4c246231a065/9f7826270fb36ada1bdb9e14bc8b5123/dotnet-sdk-7.0.302-linux-x64.tar.gz && \
    tar zxf dotnet.tgz -C ${HOME}/dotnet && \
    rm -rf dotnet.tgz && \
    dotnet tool install --global Microsoft.dotnet-interactive && \
    dotnet-interactive jupyter install && \
    rm /tmp/NuGetScratch/lock/*

COPY sandbox_00000.asb /backup/sandbox.asb
COPY start-asd.sh /usr/local/bin/
COPY spaceCompanies.json /backup/
COPY example.lua /home/user/udf/
COPY aerospike.conf features.conf /etc/aerospike/
COPY .bashrc /home/${NB_USER}/.bashrc

RUN chown -R ${NB_UID} ${HOME} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike && \
    chmod +x /usr/local/bin/start-asd.sh

FROM ubuntu:20.04 as final

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100

ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LOGFILE=/var/log/aerospike/aerospike.log \
    GOROOT=/usr/local/go \
    SHELL=/bin/bash \
    JUPYTER_PORT=8888
ENV HOME=/home/${NB_USER}
ENV GOPATH=${HOME}/go \
    DOTNET_ROOT=${HOME}/dotnet
ENV PATH=$PATH:/usr/local/go/bin:${GOROOT}/bin:${GOPATH}/bin:${HOME}/dotnet:${HOME}/.dotnet/tools

USER root
WORKDIR /

# Load data
COPY --from=build . /

EXPOSE ${JUPYTER_PORT}

CMD [ "jupyter-lab", "--ip=0.0.0.0" ]

WORKDIR /home/${NB_USER}
USER ${NB_USER}

ENTRYPOINT [ "start-asd.sh" ]
