#
# Aerospike Graph all-in-one Docker file
#
FROM aerospike/aerospike-graph-service:latest as graph
USER root
RUN yum clean all && rm -rf /root/.m2/repository/* /var/cache/yum /tmp/gremlin-* /tmp/maven*

FROM amazonlinux:2 as final
USER root
WORKDIR /

COPY --from=graph . /

ARG AEROSPIKE_VERSION=6.3.0.5
ARG AEROSPIKE_TOOLS_VERSION=8.4.0
ARG NB_USER=firefly
ARG NB_UID=1000
ARG NB_GID=100
ARG AEROSPIKE_URL="https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-${AEROSPIKE_TOOLS_VERSION}_el7_x86_64.tgz"
ARG MAMBA_URL="https://micro.mamba.pm/api/micromamba/linux-64/latest"

ENV AEROSPIKE_VERSION=${AEROSPIKE_VERSION} \
    LOGFILE=/var/log/aerospike/aerospike.log \
    CONDA_DIR=/opt/conda \
    NB_USER=firefly \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    TINKERPOP_VERSION='3.6.3' \
    MAVEN_VERSION='3.8.8' \
    JANSI_VERSION='2.4.0'
ENV MAMBA_ROOT_PREFIX=${CONDA_DIR} \
    PATH=$PATH:${CONDA_DIR}/bin:/opt/apache-maven-$MAVEN_VERSION/bin:/opt/gremlin-console/bin:/opt/gremlin-server/bin \
    HOME=/home/${NB_USER} \
    CONF_DIR="/opt/aerospike-firefly/conf/docker-default" \
    TINI_VERSION=v0.19.0

RUN yum update -y && \
    yum install -y  gcc gcc-c++ make python3-devel liberation-fonts bzip2 sudo wget && \
    mkdir /var/run/aerospike && \
    curl -L -o aerospike-server.tgz ${AEROSPIKE_URL} && \  
    mkdir aerospike && \
    tar xzf aerospike-server.tgz --strip-components=1 -C /aerospike && \
    rpm -Uvh /aerospike/aerospike-server-* && \
    rpm -Uvh /aerospike/aerospike-tools-* && \
    mkdir -p /opt/aerospike/lib/java && \
    mkdir -p /var/log/aerospike && \
    yum clean all && \
    rm -rf /var/cache/yum aerospike-server.tgz /aerospike && \
    echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    mkdir ${CONDA_DIR} && \
    chown -R ${NB_UID}:${NB_GID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike /opt/apache-tinkerpop-* ${CONDA_DIR} && \
    usermod -a -G aerospike ${NB_USER} && \
    chmod g+w /etc/passwd && \
    curl -Ls ${MAMBA_URL} | tar -xvj bin/micromamba && \
    eval "$(micromamba shell hook -s bash)" && \
    micromamba shell init -s bash -p ${CONDA_DIR} && \
    micromamba activate && \
    micromamba install --root-prefix="${CONDA_DIR}" --prefix="${CONDA_DIR}" --yes jupyter_core notebook jupyterhub jupyterlab -c conda-forge && \
    micromamba clean --all -f -y && \
    jupyter notebook --generate-config && \
    curl -L -o ijava-kernel.zip "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" && \
    unzip ijava-kernel.zip -d ijava-kernel && \
    python3 ijava-kernel/install.py --sys-prefix && \
    python3 -m pip install --no-cache-dir aerospike gremlinpython && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf /home/${NB_USER}/.cache/yarn ijava-kernel.zip

COPY start.sh start-asd.sh start-notebook.sh start-singleuser.sh fix-permissions /usr/local/bin/
COPY aerospike.conf features.conf /etc/aerospike/
COPY firefly-graph.properties firefly-gremlin-server.yaml /opt/aerospike-firefly/conf/
COPY air-routes-small.graphml /opt/aerospike-firefly/
COPY graph-java.ipynb /home/${NB_USER}/
COPY jupyter_server_config.py /etc/jupyter/

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN chmod a+rx /usr/local/bin/fix-permissions && \
    chmod +x /usr/local/bin/start-asd.sh /usr/local/bin/start.sh /usr/local/bin/start-notebook.sh /usr/local/bin/start-singleuser.sh /tini && \
    sed -re "s/c.ServerApp/c.NotebookApp/g" /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    fix-permissions /etc/jupyter/ && \
    fix-permissions ${CONDA_DIR} && \
    fix-permissions /home/${NB_USER}

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT
CMD [ "start-notebook.sh" ]

WORKDIR /home/${NB_USER}
USER ${NB_USER}
ENTRYPOINT [ "/tini", "-g", "--", "start-asd.sh" ]
