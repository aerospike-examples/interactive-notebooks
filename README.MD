# Pull the Aerospike Graph Service image 
docker pull aerospike/aerospike-graph-service:latest

# How to Build
In the root directory of the notebook run
Run `docker buildx build -t sizing_notebook .`

# How to Run

Run `docker run -p 8888:8888 sizing_notebook`

You will see some urls in the log output - click or copy and paste one of them into your web 
browser to access the Jupyter Notebook server.
Look for lines like the following:

[C 2023-12-19 18:17:05.176 ServerApp] 
    
    To access the server, open this file in a browser:
        file:///home/firefly/.local/share/jupyter/runtime/jpserver-1-open.html
    Or copy and paste one of these URLs:
        http://3c665dfa4939:8888/lab?token=cd16aff3558263697f062592d80e117414116b14ab50d717
     or http://127.0.0.1:8888/lab?token=cd16aff3558263697f062592d80e117414116b14ab50d717
