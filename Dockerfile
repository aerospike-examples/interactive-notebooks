#
# Aerospike Graph all-in-one Docker file
#
FROM aerospike/aerospike-graph-service:latest as graph
USER root
WORKDIR /

ARG AEROSPIKE_VERSION=6.4.0.19
ARG AEROSPIKE_TOOLS_VERSION=10.0.0
ARG NB_USER=firefly
ARG NB_UID=1000
ARG NB_GID=100
ARG AEROSPIKE_URL="https://artifacts.aerospike.com/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-${AEROSPIKE_TOOLS_VERSION}_el7_x86_64.tgz"

ENV AEROSPIKE_VERSION=${AEROSPIKE_VERSION} \
    NB_USER=firefly \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    HOME=/home/${NB_USER} \
    JUPYTER_PORT=8888

# Install os updates and Aerospike 
RUN yum update -y && \
    yum install -y  tar.x86_64 gcc gcc-c++ make python3.11 python3-devel liberation-fonts bzip2 unzip sudo wget && \
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
RUN python3 -m pip install --no-cache-dir aerospike==11.0.1 gremlinpython "urllib3 <=1.26.15" jupyterlab graph-notebook==3.9.0 matplotlib pandas ipywidgets IPython && \
    curl -L -o ijava-kernel.zip "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" && \
    unzip ijava-kernel.zip -d ijava-kernel && \
    python3 ijava-kernel/install.py --sys-prefix && \
    rm -rf ijava-kernel.zip 

# Copy files 
COPY start-asd.sh /usr/local/bin/
COPY aerospike.conf /etc/aerospike/
COPY aerospike-graph.properties /opt/aerospike-graph/
COPY notebooks/. /home/${NB_USER}/
COPY data/. /home/${NB_USER}/data/

RUN chmod +x /usr/local/bin/start-asd.sh && \
    chown -R ${NB_UID}:${NB_GID} ${HOME}

EXPOSE $JUPYTER_PORT

CMD [ "jupyter", "lab", "--ip=0.0.0.0"]

WORKDIR /home/${NB_USER}
USER ${NB_USER}
ENTRYPOINT [ "start-asd.sh" ]