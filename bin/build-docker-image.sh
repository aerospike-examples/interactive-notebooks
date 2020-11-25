rm -rf target
mkdir target
cp -r docker/* target
cp -r binder-pre java python spark target/notebooks/
docker build -t ${1:-aerospike/intro-notebooks} target
