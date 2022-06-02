#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#
# This docker file is compatible with Aerospike Community Edition. It provides Java and Python environments and access to the Aerospike DB.
FROM jupyter/base-notebook:python-3.8.6

USER root

ENV AEROSPIKE_VERSION 6.0.0.1
ENV AEROSPIKE_SHA256 bdcbb2dbb2b412b48451996b17f769641f99abc7b00c7401a4f9933d2fd230f5
ENV LOGFILE /var/log/aerospike/aerospike.log
ENV PATH=$PATH:/usr/local/go/bin

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root
RUN chown -R ${NB_UID} ${HOME}

RUN  mkdir /var/run/aerospike \
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python python3-pip python3-dev python3 zulu-11 \
  && wget "https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise-${AEROSPIKE_VERSION}-ubuntu20.04.tgz" -O aerospike-server.tgz \  
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && wget "https://github.com/aerospike/aerospike-loader/releases/download/2.4.3/asloader-2.4.3-linux.x86_64.deb" -O asloader.deb \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && dpkg -i asloader.deb \
  && pip install --no-cache-dir aerospike \
  && pip install --no-cache-dir pymongo \
  && wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip \
  && unzip ijava-kernel.zip -d ijava-kernel \
  && python3 ijava-kernel/install.py --sys-prefix \
  && rm ijava-kernel.zip \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && rm -f asloader.deb \
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
     
COPY aerospike /etc/init.d/
RUN usermod -a -G aerospike ${NB_USER}

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf

RUN chown -R ${NB_UID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike

# Load data
RUN mkdir /backup
COPY sandbox_00000.asb /backup/sandbox.asb 

COPY jupyter_notebook_config.py /home/${NB_USER}/
RUN  fix-permissions /home/${NB_USER}/

# I don't know why this has to be like this 
# rather than overiding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh
WORKDIR /home/${NB_USER}  
USER ${NB_USER}
