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

# BEGIN TEST

# timezone needs to be set before nodejs kernel
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone\
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends\
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python python3-pip python3-dev python3 zulu-11\
  && sudo apt-get install git -y\
  && sudo apt-get install -y nodejs npm\
  && sudo npm install -g npm\
  && npm install express\
  && npm install aerospike\
  && sudo npm cache clean -f\
  && sudo npm install -g n\
  && sudo n stable\
  && wget -O go.tgz https://golang.org/dl/go1.17.3.linux-amd64.tar.gz\
  && tar -C /usr/local -xzf go.tgz\
  && rm go.tgz\
  && go install github.com/gopherdata/gophernotes@v0.7.3\
  && go get github.com/aerospike/aerospike-client-go/v5\
  && mkdir /var/run/aerospike\
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
  && sudo apt-get install libssl-dev\
  && wget https://artifacts.aerospike.com/aerospike-client-c/5.2.5/aerospike-client-c-libuv-5.2.5.ubuntu20.04.x86_64.tgz -O aerospike-client-c.tgz\
  && tar xvf aerospike-client-c.tgz\
  && rm aerospike-client-c.tgz\
  && cd aerospike-client-c-libuv-5.2.5.ubuntu20.04.x86_64\
  && sudo dpkg -i aerospike-client-c-libuv-devel-5.2.5.ubuntu20.04.x86_64.deb\
  && sudo dpkg -i aerospike-client-c-libuv-5.2.5.ubuntu20.04.x86_64.deb\
  && cd ${HOME}\
  && git clone https://github.com/XaverKlemenschits/jupyter-c-kernel.git\
  && cd jupyter-c-kernel\
  && pip install -e .\
  && cd jupyter_c_kernel && install_c_kernel --user\
  && mkdir -p ~/.local/share/jupyter/kernels/gophernotes\
  && cd ~/.local/share/jupyter/kernels/gophernotes\
  && cp $(go env GOPATH)/pkg/mod/github.com/gopherdata/gophernotes@v0.7.3/kernel/* "."\
  && sed "s_gophernotes_$(go env GOPATH)/bin/gophernotes_" <kernel.json.in >kernel.json\
  && cd $(go env GOPATH)/pkg/mod/github.com/aerospike/aerospike-client-go/v5@v5.6.0\
  && go get -u\
  && go mod tidy\
  && cd $(go env GOPATH)/pkg/mod/github.com/go-zeromq/zmq4@v0.13.0\
  && go get -u\
  && go mod tidy\
  && cd $(go env GOPATH)/pkg/mod/github.com/gopherdata/gophernotes@v0.7.3\  
  && go get -u\
  && go mod tidy\
  && mkdir -p /var/log/aerospike  

COPY aerospike /etc/init.d/
RUN usermod -a -G aerospike ${NB_USER}

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf

RUN chown -R ${NB_UID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike

#RUN fix-permissions /etc/aerospike/
#RUN fix-permissions /var/log/aerospike

COPY jupyter_notebook_config.py /home/${NB_USER}/

RUN  fix-permissions /home/${NB_USER}/

# register js kernel
# these have to run near the end or else they error out
RUN npm install -g --unsafe-perm zeromq\
  && npm install -g --unsafe-perm ijavascript\
  && ijsinstall --spec-path=full --working-dir=${HOME}

# I don't know why this has to be like this 
# rather than overiding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh
#I had to do this to get the container to launch, not sure what I was doing wrong
RUN chmod +x /usr/local/bin/start-notebook.sh
WORKDIR /home/${NB_USER}
USER ${NB_USER}