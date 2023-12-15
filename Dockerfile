#
# Aerospike Graph all-in-one Docker file
#
FROM aerospike/aerospike-graph-service:latest as graph
USER root
RUN yum clean all && rm -rf /root/.m2/repository/* /var/cache/yum /tmp/gremlin-* /tmp/maven*

# Create build image
FROM amazonlinux:2 as build
USER root
WORKDIR /

COPY --from=graph . /

ARG AEROSPIKE_VERSION=6.3.0.5
ARG AEROSPIKE_TOOLS_VERSION=8.4.0
ARG NB_USER=firefly
ARG NB_UID=1000
ARG NB_GID=100
ARG AEROSPIKE_URL="https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-${AEROSPIKE_TOOLS_VERSION}_el7_x86_64.tgz"

ENV AEROSPIKE_VERSION=${AEROSPIKE_VERSION} \
    NB_USER=firefly \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID}

# Install os updates and Aerospike 
RUN yum update -y && \
    yum install -y  tar.x86_64 gcc gcc-c++ make python3-devel liberation-fonts bzip2 sudo wget && \
    mkdir /var/run/aerospike && \
    curl -L -o aerospike-server.tgz ${AEROSPIKE_URL} && \  
    mkdir aerospike && \
    tar xzf aerospike-server.tgz --strip-components=1 -C /aerospike && \
    rpm -Uvh /aerospike/aerospike-server-* && \
    mkdir -p /opt/aerospike/lib/java && \
    mkdir -p /var/log/aerospike && \
    yum clean all && \
    rm -rf /var/cache/yum aerospike-server.tgz /aerospike && \
    chown -R ${NB_UID}:${NB_GID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike /opt/apache-tinkerpop-* && \
    usermod -a -G aerospike ${NB_USER}

# Install client, kernels, and extensions
RUN python3 -m pip install --no-cache-dir aerospike==13.0.0 gremlinpython "urllib3 <=1.26.15" jupyterlab graph-notebook && \
    curl -L -o ijava-kernel.zip "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" && \
    unzip ijava-kernel.zip -d ijava-kernel && \
    python3 ijava-kernel/install.py --sys-prefix && \
    rm -rf ijava-kernel.zip 

# Copy files 
COPY start-asd.sh /usr/local/bin/
COPY aerospike.conf features.conf /etc/aerospike/
COPY firefly-graph.properties firefly-gremlin-server.yaml /opt/aerospike-firefly/conf/
COPY air-routes-small-latest.graphml /opt/aerospike-firefly/
COPY graph-notebook.ipynb /home/${NB_USER}/

RUN chmod +x /usr/local/bin/start-asd.sh 

# Create final image
FROM amazonlinux:2 as final
USER root
WORKDIR /

ARG AEROSPIKE_VERSION=6.3.0.5
ARG AEROSPIKE_TOOLS_VERSION=8.4.0
ARG NB_USER=firefly
ARG NB_UID=1000
ARG NB_GID=100

ENV AEROSPIKE_VERSION=${AEROSPIKE_VERSION} \
    LOGFILE=/var/log/aerospike/aerospike.log \
    NB_USER=firefly \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    TINKERPOP_VERSION='3.6.3' \
    MAVEN_VERSION='3.8.8' \
    JANSI_VERSION='2.4.0'
ENV PATH=$PATH:/opt/apache-maven-$MAVEN_VERSION/bin:/opt/gremlin-console/bin:/opt/gremlin-server/bin \
    HOME=/home/${NB_USER} \
    CONF_DIR="/opt/aerospike-firefly/conf/docker-default" \
    JUPYTER_PORT=8888

COPY --from=build . /
EXPOSE $JUPYTER_PORT

CMD [ "jupyter", "lab", "--ip=0.0.0.0"]

WORKDIR /home/${NB_USER}
USER ${NB_USER}
ENTRYPOINT [ "start-asd.sh" ]
