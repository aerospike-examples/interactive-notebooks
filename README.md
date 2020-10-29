# Aerospike 

Aerospike is an open source distributed database. Aerospike is built on a 
"shared nothing" architecture designed to reliably stores terabytes of data 
with automatic fail-over, replication and cross data-center synchronization.

Documentation for Aerospike is available at [http://aerospike.com/docs](http://aerospike.com/docs).

# Using this Image

1) Git clone image repo:

```
git clone https://github.com/citrusleaf/aerospike-dev-notebooks.docker.git
```

2) cd to "aerospike-dev-notebooks.docker" and build from Dockerfile:

```
docker build -t aerospike/aerospike-nb .
```

3) Run the image and expose port 8888 :

```
docker run -tid --name aero-nb -p 3000:3000 -p 3001:3001 -p 8888:8888 aerospike/aerospike-nb
```


4) Get the internal IP address of the container:

```
docker exec -ti aero-nb asadm -e "asinfo -v service"
```

5) Run the Jupyter notebook and configure to listen on that IP address :

```
docker exec -ti aero-nb jupyter notebook --no-browser --ip=172.17.0.2 --port=8888 --notebook-dir=/interactive-notebooks/aerospike
```

6) Use the loopback URL and token parameter from the command above to access the Jupyter notebook:

```
http://127.0.0.1:8888/?token=<token>
```

7) Example run with URL:

```
$ docker run -tid --rm --name aero-nb -p 3000:3000 -p 8888:8888 aerospike/aerospike-nb
0e7fd567d672fbbbe85ae4686f48a8ba94c5cd7b3c6348c9c5d2cb5bccaa1e46
~/Development/aerospike-dev-notebooks.docker $ docker exec -ti aero-nb jupyter notebook --no-browser --ip=172.17.0.2 --port=8888 --notebook-dir=/interactive-notebooks/aerospike
[I 21:07:07.445 NotebookApp] Writing notebook server cookie secret to /root/.local/share/jupyter/runtime/notebook_cookie_secret
[I 21:07:07.992 NotebookApp] Serving notebooks from local directory: /interactive-notebooks/aerospike
[I 21:07:07.992 NotebookApp] Jupyter Notebook 6.1.4 is running at:
[I 21:07:07.992 NotebookApp] http://172.17.0.2:8888/?token=c557afda48fcc618d82e80084befd27b81f3887b8836cbd0
[I 21:07:07.992 NotebookApp]  or http://127.0.0.1:8888/?token=c557afda48fcc618d82e80084befd27b81f3887b8836cbd0
[I 21:07:07.992 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 21:07:07.998 NotebookApp] 
    
    To access the notebook, open this file in a browser:
        file:///root/.local/share/jupyter/runtime/nbserver-160-open.html
    Or copy and paste one of these URLs:
        http://172.17.0.2:8888/?token=c557afda48fcc618d82e80084befd27b81f3887b8836cbd0
     or http://127.0.0.1:8888/?token=c557afda48fcc618d82e80084befd27b81f3887b8836cbd0
[W 21:07:11.029 NotebookApp] Forbidden
[W 21:07:11.030 NotebookApp] 403 GET /api/contents/aerospike_basic_example.ipynb?content=0&_=1603943529323 (172.17.0.1) 1.48ms referer=http://127.0.0.1:8888/notebooks/aerospike_basic_example.ipynb
[W 21:07:11.039 NotebookApp] Forbidden
[W 21:07:11.039 NotebookApp] 403 PUT /api/contents/aerospike_basic_example.ipynb (172.17.0.1) 1.07ms referer=http://127.0.0.1:8888/notebooks/aerospike_basic_example.ipynb

```



