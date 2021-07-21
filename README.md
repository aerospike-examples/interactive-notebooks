# Aerospike Interactive Notebooks

Aerospike is a distributed database designed to serve global applications
with low latency, fast throughput, and resiliency to failures.

This repository contains Jupyter notebooks for:
- **Aerospike Clients**: These notebooks illustrate the use of APIs, features, and use cases for Java and Python clients. They run in a Docker container that provides a working environment consisting of the Aerospike server, Java and Python client libraries, tools, and the Jupyter server. [This section](#run-client-notebooks-in-docker-container) describes how to run the Docker container.
- **Spark**: These notebooks show how Aerospike can be used in conjunction with Spark. Refer to [this section](#spark-notebooks) that describes how to set up and run Spark notebooks on [Linux (CentOS)](#set-up-spark-notebooks-on-linux-centos) and [MacOS X](#set-up-spark-notebooks-on-macos-x).

View the list of all notebooks [here](notebooks/README.md#notebooks).

Documentation for Aerospike is available at [https://aerospike.com/docs](https://aerospike.com/docs),
and Docker Desktop installation at [https://docs.docker.com/desktop/](https://docs.docker.com/desktop/).

The download and use of this Aerospike software is governed by [Aerospike Evaluation License Agreement](https://www.aerospike.com/forms/evaluation-license-agreement/).

## Run Client Notebooks in Docker Container
Notebooks for Java and Python clients are currently avaialble.

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

## Spark Notebooks
Spark notebooks can run on Linux (CentOS) and MacOS X.

### Set up Spark Notebooks on Linux (CentOS)

yum installer used below - use dbpkg/rpm/other if your Linux distribution does not support yum

``` bash
sudo yum -y install gcc zlib-devel openssl-devel libffi-devel sqlite-devel bzip2-devel bzip2 xz-devel screen wget
```

Get your own local copy of Python 3.7 (ignore if you have it already). Below we install to ~/.localpython

``` bash
PYTHON_VERSION=3.7.1
wget http://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
tar zxvf Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}
mkdir ~/.localpython
./configure --prefix=$HOME/.localpython
make
make install
```

Set up a virtual Python environment - this is a sandbox which avoids you making system wide changes

``` bash
# Install virtualenv tool
~/.localpython/bin/pip3 install virtualenv
# Create on-disk representation of virtual environment at ~/spark-venv
~/.localpython/bin/virtualenv ~/spark-venv
# Activate virtual environment
source ~/spark-venv/bin/activate
```

Use of a virtual environment is indicated in the command line string - the name of the virtual environment - spark-env is added to the command line prompt - e.g.,

```
(spark-venv) [ec2-user@ip-10-0-0-248 Python-3.7.1]$
```

You can return to the system enviroment by typing ```deactivate``` and reactivate using ```source ~/spark-venv/bin/activate```

Get rid of annoying messages concerning pip upgrade

```
pip install --upgrade pip
```

Note at this point, all our Python related tooling is local to our virtual environment. So ```which pip``` will give

```
~/spark-venv/bin/pip
```

Install required Python dependencies

```
pip install jupyter PySpark findspark numpy pandas matplotlib sklearn
```

If you plan on using scala in your workbooks you need to install the spylon kernel - some care is needed with Python versioning
```
pip install spylon_kernel
PYTHON=$(which python)
sudo $PYTHON -m spylon_kernel install
```

Install Spark and set ```$SPARK_HOME```. Note you may need to change the SPARK_VERSION if you get a 404 following the wget.

``` bash
SPARK_VERSION=2.4.7
HADOOP_VERSION=2.7
cd /tmp
wget https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
tar xvfz spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
sudo mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/
export SPARK_HOME=/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH
cd ~
```

Use of the Aerospike Spark Connector requires a valid feature key. The notebooks assume this is located at ```/etc/aerospike/features.conf```. Make sure your feature key is locally available, and if it is not located as above, modify the ```AS_FEATURE_KEY_PATH``` variable at the head of the notebook. You may need to run

``` bash
sudo mkdir /etc/aerospike
sudo chmod 777 /etc/aerospike
```

Make sure you have the interactive-notebooks repository locally.

```
git clone https://github.com/aerospike-examples/interactive-notebooks
```
Finally start Jupyter. Change the IP in the string below - it can be localhost, but if you want to access from a remote host, choose the IP of one of your ethernet interfaces. You could replace with $(hostname -I | awk '{print $1}')

Note I set the notebook-dir to point to the directory containing the notebooks in this repository. You also will need SPARK_HOME and PYTHONPATH set correctly (reproducing the former from the above).

```
SPARK_VERSION=2.4.7
HADOOP_VERSION=2.7
export SPARK_HOME=/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH
jupyter notebook --no-browser --ip=<IP> --port=8888 --notebook-dir=~/interactive-notebooks/spark/
```

You will see output similar to

```
[I 09:36:52.202 NotebookApp] Writing notebook server cookie secret to /home/ec2-user/.local/share/jupyter/runtime/notebook_cookie_secret
[I 09:36:52.370 NotebookApp] Serving notebooks from local directory: /home/ec2-user/interactive-notebooks/spark
[I 09:36:52.370 NotebookApp] Jupyter Notebook 6.1.4 is running at:
[I 09:36:52.370 NotebookApp] http://10.0.0.248:8888/?token=5bf2910a2527567346323e0a4735e94136e1c70d392b561f
[I 09:36:52.370 NotebookApp]  or http://127.0.0.1:8888/?token=5bf2910a2527567346323e0a4735e94136e1c70d392b561f
[I 09:36:52.371 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 09:36:52.373 NotebookApp]
```

You will need to use the URLs in the output to access jupyter - as the security token is expected.

You can omit this step by omitting the --no-browser flag - in that case jupyter will open a browser window local to itself, and request the Notebook app URL above.

You may wish to run the jupyter startup command from a [screen](https://linuxize.com/post/how-to-use-linux-screen/) so it will stay running if your session terminates. We installed screen at the outset to allow for this.

#### pyenv / Linux

You can go down the pyenv route on Linux as per the instructions for Mac. You install pyenv differently

```
sudo yum -y install gcc git zlib-devel openssl-devel libffi-devel sqlite-devel bzip2-devel bzip2 xz-devel screen
git clone http://github.com/pyenv/pyenv .pyenv
export PATH=$PATH:~/.pyenv/bin
```

but once done, just pick up the MacOS instructions at ```pyenv install 3.7.3```

### Set Up Spark Notebooks on MacOS X
The main challenge is getting a sufficiently up to date version of Python installed and set as your working version. You mustn't mess with your existing version of Python (see [xkcd](https://xkcd.com/1987/)).

[pyenv](https://github.com/pyenv/pyenv) is the tool to help with this.

First you'll need **brew** the package manager for macOS. From  [instructions](https://brew.sh)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

Next install pyenv
```
brew install pyenv
```
and finally we can install our required python version. The subsequent 'global' command sets 3.7.3 as our selected version
```
pyenv install 3.7.3
pyenv global 3.7.3
```
The command below sets up our path so the required version of Python is used. Once done, do ```python --version``` to check.
```
eval "$(pyenv init -)"
```
You can now set up your virtual environment - this is a sandbox which avoids you making system wide changes. Note this is the same as the steps above for Linux, except we don't have  to give explicit paths to pip, virtualenv.

``` bash
# Install virtualenv tool
pip install virtualenv
# Create on-disk representation of virtual environment at ~/spark-venv
virtualenv ~/spark-venv
# Activate virtual environment
source ~/spark-venv/bin/activate
```

You can now follow the Linux instructions from
```
pip install jupyter PySpark findspark numpy pandas matplotlib sklearn
```

onwards.
