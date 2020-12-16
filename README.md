# Aerospike 

Aerospike is an open source distributed database. Aerospike is built on a 
"shared nothing" architecture designed to reliably stores terabytes of data 
with automatic fail-over, replication and cross data-center synchronization.

Documentation for Aerospike is available at [http://aerospike.com/docs](http://aerospike.com/docs),
and Docker Desktop installation at : [https://docs.docker.com/desktop/](https://docs.docker.com/desktop/)

## Using this Image

1. Install [Docker](https://www.docker.io/).

1. Get the image.

   Download the image from [the public Docker Registry](https://index.docker.io/).
   ```
   docker pull aerospike/intro-notebooks
   ```
      (If building the image:
      1. Git clone image repo:
         ```
         git clone https://github.com/citrusleaf/aerospike-dev-notebooks.docker.git
         ```
      1. cd to "aerospike-dev-notebooks.docker" and build from Dockerfile: <br>
         ```
         docker build -t aerospike/aerospike-dev-notebooks .
         ```
1. Run the image and expose port 8888 :
   ```
   docker run --name aero-nb -p 8888:8888 aerospike/aerospike-dev-notebooks
   ```
   Use LOGFILE environment variable to specify a log file path in the image:
   ```
   docker run -e "LOGFILE=/opt/aerospike/aerospike.log" --name aero-nb -p 8888:8888 aerospike/aerospike-dev-notebooks
   ```
1. The url with token should be printed on the output. By default it should be 
   ```
   http://127.0.0.1:8888/?token=<token>
   ```
1. Example run with URL:
   ```text
   $ docker run --name aero-nb -p 8888:8888 aerospike/aerospike-dev-notebooks

   link eth0 state up
   link eth0 state up in 0
   Set username to: jovyan
   usermod: no changes
   Executing the command: jupyter notebook
   [I 05:28:34.202 NotebookApp] Writing notebook server cookie secret to /home/jovyan/.local/share/jupyter/runtime/notebook_cookie_secret
   [I 05:28:34.954 NotebookApp] JupyterLab extension loaded from /opt/conda/lib/python3.8/site-packages/jupyterlab
   [I 05:28:34.954 NotebookApp] JupyterLab application directory is /opt/conda/share/jupyter/lab
   [I 05:28:34.957 NotebookApp] Serving notebooks from local directory: /home/jovyan/notebooks
   [I 05:28:34.957 NotebookApp] Jupyter Notebook 6.1.4 is running at:
   [I 05:28:34.957 NotebookApp] http://6a374afd9f00:8888/?token=c45783e6631e305c97f6919905250e61f09049e750813cf6
   [I 05:28:34.957 NotebookApp]  or http://127.0.0.1:8888/?token=c45783e6631e305c97f6919905250e61f09049e750813cf6
   [I 05:28:34.957 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).

   ```
