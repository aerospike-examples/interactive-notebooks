## Aerospike Development Notebooks Dockerfile

This repository contains the Dockerfile for building a Docker image for running [Aerospike](http://aerospike.com). 

## Installation

1. Install [Docker](https://www.docker.io/).

2. Download from public [Docker Registry](https://index.docker.io/):

		docker pull aerospike-examples/interactive-notebooks

	_Alternatively, you can build an image from Dockerfile:_
   
		docker build -t="aerospike-examples/interactive-notebooks" github.com/aerospike-examples/interactive-notebooks
