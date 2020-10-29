#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#

FROM ubuntu:18.04

#ENV AEROSPIKE_VERSION 5.2.0.5

# Install Aerospike Server and Tools


RUN \
  apt-get update -y \
  && apt-get install -y procps curl iproute2 wget python build-essential  lua5.2 gettext-base libcurl4-openssl-dev libssl-dev zlib1g-dev vim net-tools telnet python3-pip python3-dev git  \
  && pip3 -q install pip --upgrade \
  && pip3 install --no-cache-dir vdom==0.5 notebook cryptography psutil jupyter findspark numpy pandas matplotlib sklearn ipython\
  && pip3 install aerospike \
  && wget "https://www.aerospike.com/download/server/latest/artifact/ubuntu18" -O aerospike-server.tgz \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && git clone https://github.com/aerospike-examples/interactive-notebooks.git \
  && mkdir -p /var/log/aerospike/ \
  && mkdir -p /var/run/aerospike/ \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y 

  


# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY entrypoint.sh /entrypoint.sh
COPY aerospike /etc/init.d/
COPY jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py

# Mount the Aerospike data directory
# VOLUME ["/opt/aerospike/data"]
# Mount the Aerospike config directory
# VOLUME ["/etc/aerospike/"]


# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#
EXPOSE 3000 3001 3002 3003

# Execute the run script in foreground mode
ENTRYPOINT ["/entrypoint.sh"]
CMD ["asd"]
