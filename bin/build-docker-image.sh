rm -rf target
mkdir target
cp -r docker/* target
cp -r java python target/notebooks/
docker build -t ${1:-aerospike/intro-notebooks} target
