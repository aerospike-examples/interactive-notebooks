# Aerospike 

Aerospike is an open source distributed database. Aerospike is built on a 
"shared nothing" architecture designed to reliably stores terabytes of data 
with automatic fail-over, replication and cross data-center synchronization.

This repository provides a Docker container that has a working environment with Aerospike server, Java and Python client libraries, and Jupyter notebooks to illustrate the use of Aerospike APIs, features, and use cases. View the list of the notebooks [here](notebooks/README.md#notebooks). 

Visit [this repo](https://github.com/aerospike-examples/interactive-notebooks) for Jupyter notebooks showing how Aerospike can be used in conjunction with Spark.

Documentation for Aerospike is available at [https://aerospike.com/docs](https://aerospike.com/docs),
and Docker Desktop installation at : [https://docs.docker.com/desktop/](https://docs.docker.com/desktop/)

The download and use of this Aerospike software is governed by [Aerospike Evaluation License Agreement](https://www.aerospike.com/forms/evaluation-license-agreement/). 

## Using this Image

1. Install [Docker](https://www.docker.com).

1. Get [the Intro Notebooks image](https://hub.docker.com/r/aerospike/intro-notebooks) from [Docker Hub](https://hub.docker.com/u/aerospike):
   ```
   docker pull aerospike/intro-notebooks
   ```
      [Alternatively] If building the image:
      1. Git clone image repo:
         ```
         git clone https://github.com/aerospike/aerospike-dev-notebooks.docker.git
         ```
      1. cd to "aerospike-dev-notebooks.docker" and build from Dockerfile:
         ```
         docker build -t aerospike/intro-notebooks .
         ```
1. Run the image and expose port 8888:
   ```
   docker run --name aero-nb -p 8888:8888 aerospike/intro-notebooks
   ```
   [Optional alternative] Use the LOGFILE environment variable to specify a log file path in the image:
   ```
   docker run -e "LOGFILE=/opt/aerospike/aerospike.log" --name aero-nb -p 8888:8888 aerospike/intro-notebooks
   ```
1. Point your browser at the url with token which should be printed on the output. By default it should be:
   ```
   http://127.0.0.1:8888/?token=<token>
   ```

Example:
```text
$ docker run --name aero-nb -p 8888:8888 aerospike/intro-notebooks

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
