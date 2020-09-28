#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#

FROM jupyter/all-spark-notebook:ubuntu-18.04
RUN pip install --no-cache-dir vdom==0.5
RUN pip install --no-cache-dir notebook
RUN pip install --no-cache-dir cryptography
RUN pip install --no-cache-dir aerospike
RUN pip install --no-cache-dir psutil








# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#

# Install Aerospike Server and Tools

USER root
ENV AEROSPIKE_VERSION 5.1.0.10
ENV AEROSPIKE_SHA256 5d02c872ae232110da3cd3354c22e7822fd7bbc68fdf7ceb384664acef0ebdfc
ENV AEROSPIKE_SPARK_CONNECTOR_VERSION 2.4.0
# Install Aerospike Server and Tools

RUN \
  apt-get update -y \
  && apt-get install -y wget python lua5.2 gettext-base libldap-dev libcurl3 libcurl3-gnutls\
  # TODO: Need to add new enterprise link. The below link cuurently needs authentication.
  && wget "https://www.aerospike.com/enterprise/download/server/${AEROSPIKE_VERSION}/artifact/debian9" -O aerospike-server.tgz \
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && wget https://www.aerospike.com/artifacts/aerospike-spark/${AEROSPIKE_SPARK_CONNECTOR_VERSION}/aerospike-spark-assembly-${AEROSPIKE_SPARK_CONNECTOR_VERSION}.jar -O /usr/local/spark/jars/aerospike-spark-assembly-${AEROSPIKE_SPARK_CONNECTOR_VERSION}.jar\
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && mkdir -p /var/log/aerospike/ \
  && mkdir -p /var/run/aerospike/ \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y 


# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY entrypoint.sh /entrypoint.sh
COPY spark /home/$NB_USER/spark
COPY aerospike /home/$NB_USER/aerospike

# Mount the Aerospike data directory
#VOLUME ["/opt/aerospike/data"]

# Mount the Aerospike config directory
#VOLUME ["/etc/aerospike/"]


# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#
EXPOSE 3000 3001 3002 3003
RUN /entrypoint.sh
#USER $NB_UID