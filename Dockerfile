#
# Aerospike Graph all-in-one Docker file
#
FROM aerospike/aerospike-graph-service:latest

ARG AEROSPIKE_VERSION=6.3.0.2
ARG AEROSPIKE_TOOLS_VERSION=8.3.0
ARG NB_USER=firefly
ARG NB_UID=1000
ARG NB_GID=100
ARG AEROSPIKE_URL="https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise_${AEROSPIKE_VERSION}_tools-${AEROSPIKE_TOOLS_VERSION}_el7_x86_64.tgz"
ARG MAMBA_URL="https://micro.mamba.pm/api/micromamba/linux-64/latest"

ENV AEROSPIKE_VERSION=${AEROSPIKE_VERSION} \
    LOGFILE=/var/log/aerospike/aerospike.log \
    CONDA_DIR=/opt/conda \
    NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} 
ENV MAMBA_ROOT_PREFIX=${CONDA_DIR} \
    PATH=$PATH:${CONDA_DIR}/bin \
    HOME=/home/${NB_USER}

SHELL [ "/bin/bash", "-c" ]
USER root
WORKDIR /

RUN yum update -y && \
    yum install -y  gcc gcc-c++ make python3-devel liberation-fonts bzip2 sudo wget && \
    mkdir /var/run/aerospike && \
    curl -L -o aerospike-server.tgz ${AEROSPIKE_URL} && \  
    mkdir aerospike && \
    tar xzf aerospike-server.tgz --strip-components=1 -C /aerospike && \
    rpm -Uvh /aerospike/aerospike-server-* && \
    rpm -Uvh /aerospike/aerospike-tools-* && \
    mkdir -p /opt/aerospike/lib/java && \
    rm -rf aerospike-server.tgz /aerospike && \
    yum clean all && \
    mkdir -p /var/log/aerospike

# Set up user and permissions for notebook
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    mkdir ${CONDA_DIR} && \
    chown ${NB_USER} ${CONDA_DIR} && \
    chown -R ${NB_UID} /etc/aerospike /opt/aerospike /var/log/aerospike /var/run/aerospike /opt/apache-tinkerpop-* && \
    usermod -a -G aerospike ${NB_USER} && \
    chmod g+w /etc/passwd

COPY .bashrc /home/${NB_USER}/

RUN curl -Ls ${MAMBA_URL} | tar -xvj bin/micromamba && \
    eval "$(micromamba shell hook -s bash)" && \
    micromamba shell init -s bash -p ${CONDA_DIR} && \
    micromamba activate && \
    micromamba install --root-prefix="${CONDA_DIR}" --prefix="${CONDA_DIR}" --yes jupyter_core notebook jupyterhub jupyterlab -c conda-forge && \
    micromamba clean --all -f -y && \
    jupyter notebook --generate-config && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    curl -L -o ijava-kernel.zip "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" && \
    unzip ijava-kernel.zip -d ijava-kernel && \
    python3 ijava-kernel/install.py --sys-prefix && \
    python3 -m pip install --no-cache-dir aerospike gremlinpython && \
    rm ijava-kernel.zip 

# Copy files
COPY start-notebook.sh start-singleuser.sh start-asd.sh start.sh fix-permissions /usr/local/bin/
COPY aerospike.conf features.conf /etc/aerospike/
COPY firefly-graph.properties firefly-gremlin-server.yaml /opt/aerospike-firefly/conf/
COPY air-routes-small.graphml /opt/aerospike-firefly/
COPY graph-java.ipynb /home/${NB_USER}/
COPY jupyter_server_config.py /etc/jupyter/

RUN chmod a+rx /usr/local/bin/fix-permissions && \
    chmod +x /usr/local/bin/start.sh /usr/local/bin/start-notebook.sh /usr/local/bin/start-asd.sh && \
    sed -re "s/c.ServerApp/c.NotebookApp/g" /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    fix-permissions /etc/jupyter/ && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

CMD [ "jupyter", "lab" ]
ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

WORKDIR /home/${NB_USER}
USER ${NB_USER}

ENTRYPOINT ["start-asd.sh"]
