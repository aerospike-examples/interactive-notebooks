#rm -rf target
#mkdir target
#cp -r docker/* target
#cp -r notebooks/java target/notebooks/
#cp -r notebooks/python target/notebooks/

docker build --no-cache -t ${1:-aerospike/intro-notebooks} .
