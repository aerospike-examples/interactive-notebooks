FROM jupyter/base-notebook:latest

USER root

ENV AEROSPIKE_VERSION 5.2.0.6
ENV AEROSPIKE_SHA256 2e3f609489bc7cd7aa82b6dd6eb01718c0db54af2c732bc141c20670acc02c0a

RUN \
  apt-get update -y \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev software-properties-common curl unzip\
  && apt-get install -y dirmngr --install-recommends\
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && wget "https://www.aerospike.com/artifacts/aerospike-server-community/${AEROSPIKE_VERSION}/aerospike-server-community-${AEROSPIKE_VERSION}-ubuntu18.04.tgz" -O aerospike-server.tgz \  
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && pip install --no-cache-dir cryptography\
  && pip install --no-cache-dir aerospike\
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt install -y zulu-11\
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y 


# Unpack and install the java kernel
RUN curl -L https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip > ijava-kernel.zip
RUN unzip ijava-kernel.zip -d ijava-kernel \
  && cd ijava-kernel \
  && python3 install.py --sys-prefix
RUN rm ijava-kernel.zip

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
RUN fix-permissions /etc/aerospike/

COPY aerospike /home/${NB_USER}/notebooks/aerospike
COPY python /home/${NB_USER}/notebooks/python
COPY java /home/${NB_USER}/notebooks/java
RUN fix-permissions /home/${NB_USER}/


# I don't know why this has to be like this 
# rather than overriding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh

WORKDIR /home/${NB_USER}/notebooks
