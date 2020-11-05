# Aerospike 

Aerospike is an open source distributed database. Aerospike is built on a 
"shared nothing" architecture designed to reliably stores terabytes of data 
with automatic fail-over, replication and cross data-center synchronization.

Documentation for Aerospike is available at [http://aerospike.com/docs](http://aerospike.com/docs),
and Docker Desktop installation at : [https://docs.docker.com/desktop/](https://docs.docker.com/desktop/)

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



8) Running Java examples

```
$ docker exec -ti aero-nb bash
root@c960513b794c:/# cd java_client/
root@c960513b794c:/java_client# ls
aerospike-client-java-5.0.0
root@c960513b794c:/java_client# cd aerospike-client-java-5.0.0/
root@c960513b794c:/java_client/aerospike-client-java-5.0.0# ls
LICENSE.md  README.md  benchmarks  build_all  client  examples  pom.xml  servlets  test
root@c960513b794c:/java_client/aerospike-client-java-5.0.0# 

root@c960513b794c:/# cd java_client/aerospike-client-java-5.0.0/examples/
root@c960513b794c:/java_client/aerospike-client-java-5.0.0/examples# ls
README.md  pom.xml  run_examples  run_examples_swing  src  target  udf
root@c960513b794c:/java_client/aerospike-client-java-5.0.0/examples# ./run_examples
usage: com.aerospike.examples.Main [<options>] all|(<example1> <example2> ...)
options:
-auth <arg>                         Authentication mode. Values: [INTERNAL, EXTERNAL,
                                    EXTERNAL_INSECURE]
-d,--debug                          Run in debug mode.
-g,--gui                            Invoke GUI to selectively run tests.
-h,--host <arg>                     List of seed hosts in format:
                                    hostname1[:tlsname][:port1],...
                                    The tlsname is only used when connecting with a secure TLS
                                    enabled server. If the port is not specified, the default port
                                    is used.
                                    IPv6 addresses must be enclosed in square brackets.
                                    Default: localhost
                                    Examples:
                                    host1
                                    host1:3000,host2:3000
                                    192.168.1.10:cert1:3000,[2001::1111]:cert2:3000
-n,--namespace <arg>                Namespace (default: test)
-netty                              Use Netty NIO event loops for async examples
-nettyEpoll                         Use Netty epoll event loops for async examples (Linux only)
-p,--port <arg>                     Server default port (default: 3000)
-P,--password <arg>                 Password
-s,--set <arg>                      Set name. Use 'empty' for empty set (default: demoset)
-tls,--tlsEnable                    Use TLS/SSL sockets
-tlsCiphers,--tlsCipherSuite <arg>  Allow TLS cipher suites
                                    Values:  cipher names defined by JVM separated by comma
                                    Default: null (default cipher list provided by JVM)
-tlsLoginOnly                       Use TLS/SSL sockets on node login only
-tp,--tlsProtocols <arg>            Allow TLS protocols
                                    Values:  TLSv1,TLSv1.1,TLSv1.2 separated by comma
                                    Default: TLSv1.2
-tr,--tlsRevoke <arg>               Revoke certificates identified by their serial number
                                    Values:  serial numbers separated by comma
                                    Default: null (Do not revoke certificates)
-U,--user <arg>                     User name
-u,--usage                          Print usage.

examples:
ServerInfo
PutGet
Replace
Add
Append
Prepend
Batch
Generation
Serialize
Expire
Touch
StoreKey
DeleteBin
ListMap
Operate
OperateList
ScanParallel
ScanSeries
UserDefinedFunction
QueryInteger
QueryString
QueryFilter
QueryExp
QuerySum
QueryAverage
QueryCollection
QueryRegion
QueryRegionFilter
QueryGeoCollection
QueryExecute
AsyncPutGet
AsyncBatch
AsyncQuery
AsyncScan
AsyncUserDefinedFunction

All examples will be run if 'all' is specified as an example.


```

