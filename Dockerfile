#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#
# This docker file is compatible with Aerospike Community Edition. It provides Java and Python environments and access to the Aerospike DB.
FROM jupyter/base-notebook:python-3.8.6

USER root

ENV AEROSPIKE_VERSION 6.2.0.0
ENV AEROSPIKE_SHA256 f481573aafef86ebfc2f20eb15deed426397b0f6a4afcac1be5e99d1840876a7
ENV LOGFILE /var/log/aerospike/aerospike.log
ARG AEROSPIKE_TOOLS_VERSION=8.0.2

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root
RUN chown -R ${NB_UID} ${HOME}

# install jupyter notebook extensions, and enable these extensions by default: table of content, collapsible headers, and scratchpad
RUN pip install jupyter_contrib_nbextensions\
  && jupyter contrib nbextension install --sys-prefix\
  && jupyter nbextension enable toc2/main --sys-prefix\
  && jupyter nbextension enable collapsible_headings/main --sys-prefix\
  && jupyter nbextension enable scratchpad/main --sys-prefix

RUN  mkdir /var/run/aerospike \
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python python3-pip python3-dev python3 zulu-11 \
  && wget "https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-${AEROSPIKE_TOOLS_VERSION}_ubuntu20.04_x86_64.tgz" -O aerospike-server.tgz \
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && wget "https://github.com/aerospike/aerospike-loader/releases/download/2.4.3/asloader-2.4.3-linux.x86_64.deb" -O asloader.deb \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools_*.deb \
  && dpkg -i asloader.deb \
  && pip install --no-cache-dir pymongo \
  && pip install --no-cache-dir aerospike \
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

#install node.js
ENV NODE_VERSION=16.13.0
RUN mkdir /usr/local/.nvm
ENV NVM_DIR=/usr/local/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION} \
  && npm install aerospike@5.0.3 \
  && npm install -g --unsafe-perm ijavascript \
  && ijsinstall --spec-path=full --working-dir=${HOME}

ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

COPY aerospike /etc/init.d/
RUN usermod -a -G aerospike ${NB_USER}

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf

RUN chown -R ${NB_UID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike

# Load data
COPY .bashrc /home/${NB_USER}/
COPY space-companies.json /home/${NB_USER}
COPY wine-data.json /home/${NB_USER}
COPY notebook-doc.ipynb /home/${NB_USER}
COPY notebook-java.ipynb /home/${NB_USER}
COPY notebook-node.ipynb /home/${NB_USER}
RUN  fix-permissions /home/${NB_USER}/

COPY entrypoint.sh /usr/local/bin/start-notebook.sh
WORKDIR /home/${NB_USER}
USER ${NB_USER}