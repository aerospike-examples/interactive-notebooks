#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#
# This docker file is compatible with Aerospike Community Edition. It provides Java and Python environments and access to the Aerospike DB.
FROM jupyter/base-notebook:python-3.8.6

USER root

ENV AEROSPIKE_VERSION 5.2.0.6
ENV AEROSPIKE_SHA256 ad984f7cac318b4033e1d8c8d521ddcd6af26768e628a16f1bcdee38eb0bd9d3
 

RUN  mkdir /var/run/aerospike\
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends\
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip zulu-11\
  && wget "https://www.aerospike.com/artifacts/aerospike-server-community/${AEROSPIKE_VERSION}/aerospike-server-community-${AEROSPIKE_VERSION}-ubuntu20.04.tgz" -O aerospike-server.tgz \  
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && pip install --no-cache-dir aerospike\
  && wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip\
  && unzip ijava-kernel.zip -d ijava-kernel \
  && python3 ijava-kernel/install.py --sys-prefix\
  && rm ijava-kernel.zip\
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y 

COPY aerospike /etc/init.d/

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
RUN fix-permissions /etc/aerospike/

COPY notebooks* /home/${NB_USER}/notebooks
RUN echo "Versions:" > /home/${NB_USER}/notebooks/README.md
RUN python -V >> /home/${NB_USER}/notebooks/README.md
RUN java -version 2>> /home/${NB_USER}/notebooks/README.md
RUN asd --version >> /home/${NB_USER}/notebooks/README.md
RUN echo -e "Aerospike Python Client `pip show aerospike|grep Version|sed -e 's/Version://g'`" >> /home/${NB_USER}/notebooks/README.md
RUN echo -e "Aerospike Java Client 5.0.0" >> /home/${NB_USER}/notebooks/README.md

COPY jupyter_notebook_config.py /home/${NB_USER}/
RUN  fix-permissions /home/${NB_USER}/

# I don't know why this has to be like this 
# rather than overiding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh

WORKDIR /home/${NB_USER}/notebooks  
