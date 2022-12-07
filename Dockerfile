#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#
# This docker file is compatible with Aerospike Community Edition. It provides Java and Python environments and access to the Aerospike DB.
FROM jupyter/base-notebook:python-3.8.6

USER root

ENV AEROSPIKE_VERSION 6.2.0.1
ENV AEROSPIKE_SHA256 f42b61b0b8dd0317e760c29ee687c1c76df79e0f77b9e27bfa4ad931b460a5e0
ENV LOGFILE /var/log/aerospike/aerospike.log
ARG AEROSPIKE_TOOLS_VERSION=8.0.3

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root
RUN chown -R ${NB_UID} ${HOME}

# spark notebook
RUN mkdir /opt/spark-nb; cd /opt/spark-nb\
  && wget -qO- "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=245467_4d5417147a92418ea8b615e228bb6935" | tar -xvz \
  && wget -qO- "https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz" | tar -xvz \
  && ln -s spark-3.1.2-bin-hadoop3.2 spark-dir-link \
  && pip install findspark numpy pandas matplotlib sklearn \
  && wget "https://download.aerospike.com/artifacts/aerospike-spark/3.5.4/aerospike-spark-3.5.4_spark_3.2_clientunshaded.jar" \
  && ln -s aerospike-spark-3.5.4_spark_3.2_clientunshaded.jar aerospike-jar-link
  
  # install jupyter notebook extensions, and enable these extensions by default: table of content, collapsible headers, and scratchpad
RUN pip install jupyter_contrib_nbextensions\
  && jupyter contrib nbextension install --sys-prefix\
  && jupyter nbextension enable toc2/main --sys-prefix\
  && jupyter nbextension enable collapsible_headings/main --sys-prefix\
  && jupyter nbextension enable scratchpad/main --sys-prefix

RUN  mkdir /var/run/aerospike\
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends\
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python python3-pip python3-dev python3 zulu-11\
  && wget "https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-${AEROSPIKE_TOOLS_VERSION}_ubuntu20.04_x86_64.tgz" -O aerospike-server.tgz \  
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && wget "https://github.com/aerospike/aerospike-loader/releases/download/2.4.3/asloader-2.4.3-linux.x86_64.deb" -O asloader.deb \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server*.deb \
  && dpkg -i aerospike/aerospike-tools*.deb \
  && dpkg -i asloader.deb \
  && pip install --no-cache-dir aerospike\
  && pip install --no-cache-dir pymongo\
  && wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip\
  && unzip ijava-kernel.zip -d ijava-kernel \
  && python3 ijava-kernel/install.py --sys-prefix\
  && rm ijava-kernel.zip\
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
   && rm -f asloader.deb \
  && apt-get purge -y \
  && apt autoremove -y \
  && mkdir -p /var/log/aerospike 

COPY aerospike /etc/init.d/
RUN usermod -a -G aerospike ${NB_USER}

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf

RUN chown -R ${NB_UID} /etc/aerospike
RUN chown -R ${NB_UID} /opt/aerospike
RUN chown -R ${NB_UID} /var/log/aerospike
RUN chown -R ${NB_UID} /var/run/aerospike

#RUN fix-permissions /etc/aerospike/
#RUN fix-permissions /var/log/aerospike

COPY notebooks* /home/${NB_USER}/notebooks
RUN echo "Versions:" > /home/${NB_USER}/notebooks/README.md
RUN python -V >> /home/${NB_USER}/notebooks/README.md
RUN java -version 2>> /home/${NB_USER}/notebooks/README.md
RUN asd --version >> /home/${NB_USER}/notebooks/README.md
RUN echo -e "Aerospike Python Client `pip show aerospike|grep Version|sed -e 's/Version://g'`" >> /home/${NB_USER}/notebooks/README.md
#RUN echo -e "Aerospike Java Client 5.0.0" >> /home/${NB_USER}/notebooks/README.md

COPY jupyter_notebook_config.py /home/${NB_USER}/
RUN  fix-permissions /home/${NB_USER}/

# I don't know why this has to be like this 
# rather than overiding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh
WORKDIR /home/${NB_USER}/notebooks  
USER ${NB_USER}
