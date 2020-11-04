FROM jbindinga/java-notebook
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
ENV AEROSPIKE_VERSION 5.2.0.6
ENV AEROSPIKE_SHA256 8f2f3e25cca86d813b159a75098dc450966ad2cf1ea92b9c7c6bca1d8712728e
#ENV AEROSPIKE_SPARK_CONNECTOR_VERSION 2.4.0
# Install Aerospike Server and Tools

RUN \
  apt-get update -y \
  && apt-get install -y wget python lua5.2 gettext-base libldap-dev libcurl3 libcurl3-gnutls\
  && wget "https://www.aerospike.com/artifacts/aerospike-server-community/${AEROSPIKE_VERSION}/aerospike-server-community-${AEROSPIKE_VERSION}-ubuntu18.04.tgz" -O aerospike-server.tgz \  
#   && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && wget "https://www.aerospike.com/download/client/java/5.0.0/artifact/jar_dependencies" -O aerospike-client-java.jar\
  #&& wget https://www.aerospike.com/artifacts/aerospike-spark/${AEROSPIKE_SPARK_CONNECTOR_VERSION}/aerospike-spark-assembly-${AEROSPIKE_SPARK_CONNECTOR_VERSION}.jar -O /usr/local/spark/jars/aerospike-spark-assembly-${AEROSPIKE_SPARK_CONNECTOR_VERSION}.jar\
  && dpkg -i aerospike/aerospike-server-*.deb \
#   && dpkg -i aerospike/aerospike-tools-*.deb \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  #&& rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y 


# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
RUN fix-permissions /etc/aerospike/

COPY aerospike /home/${NB_USER}/aerospike
COPY python /home/${NB_USER}/python
COPY java /home/${NB_USER}/java
RUN fix-permissions /home/${NB_USER}/


# I don't know why this has to be like this 
# rather than overriding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh

# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#
EXPOSE 3000 3001 3002 3003
USER $NB_USER
ENV IJAVA_CLASSPATH /home/${NB_USER}/
ENV CLASSPATH ${CLASSPATH}:${IJAVA_CLASSPATH}
