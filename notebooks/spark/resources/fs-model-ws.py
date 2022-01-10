# fs-model-ws.py
# This file implements the web service for a simple fraud prediction model from
# the Jupyter notebook feature-store-model-serving.ipynb.

from flask import Flask, jsonify
from flask_restful import Resource, Api, reqparse

app = Flask(__name__)
api = Api(app)

# globals
client = None
spark = None
rf_model = None
namespace = 'test'
entity_set = 'cctxn-features'
features = None
schema = None

class CCTxnModel(Resource): 

    # predict() processes requests and returns predictions
    @app.route('/', methods=['GET', 'POST'])
    def predict(): 
        global client, spark, rf_model, namespace, entity_set, features, schema
        
        # use parser to find txnid
        parser = reqparse.RequestParser()
        parser.add_argument('txnid')        
        args = parser.parse_args()
        txnid = args['txnid'] 
        
        # Retrieving Features
        record_key = (namespace, entity_set, txnid)
        try:
            (key, meta, bins) = client.select(record_key, features)
        except:
          import sys
          print('failed to get record')
          sys.exit(1)

        # create a input dataframe for the model
        featureBuf = [tuple([bins[f] for f in features])]
        featureRDD = spark.sparkContext.parallelize(featureBuf)            
        featureDF = spark.createDataFrame(featureRDD, schema)
        
        # Construct Feature Vector
        from pyspark.ml.feature import VectorAssembler

        # create a feature vector from features
        assembler = VectorAssembler(inputCols=features, outputCol="fvector")
        featureVectorDF = assembler.transform(featureDF)

        # Predict
        from pyspark.ml.classification import RandomForestClassificationModel
        rf_prediction = rf_model.transform(featureVectorDF['fvector', ])
        result = rf_prediction['probability', 'prediction'].collect()[0]
        
        return jsonify({'normal_prob': result[0][0], 
                'fraud_prob': result[0][1],
                'prediction':'no fraud' if result[1] < 0.5  else 'fraud'})

# add resource for processing requests
api.add_resource(CCTxnModel, '/')

# initialization of client, spark, model
def initialize():
    global client, spark, rf_model, features, schema
    
    # Initialize Client
    # connect to the database
    import aerospike
    import sys
    config = {
      'hosts': [ ('127.0.0.1', 3000) ]
    }
    try:
      client = aerospike.client(config).connect()
    except:
      print("failed to connect to the cluster with", config['hosts'])
      sys.exit(1)
    print('Client initialized and connected to database')
    
    # Initialize Spark
    # directory where spark notebook requisites are installed
    #SPARK_NB_DIR = '/home/jovyan/notebooks/spark'
    SPARK_NB_DIR = '/opt/spark-nb'
    SPARK_HOME = SPARK_NB_DIR + '/spark-3.0.3-bin-hadoop3.2'
    # IP Address or DNS name for one host in your Aerospike cluster
    AS_HOST ="localhost"
    # Name of one of your namespaces. Type 'show namespaces' at the aql prompt if you are not sure
    AS_NAMESPACE = "test" 
    AEROSPIKE_SPARK_JAR_VERSION="3.2.0"
    AS_PORT = 3000 # Usually 3000, but change here if not
    AS_CONNECTION_STRING = AS_HOST + ":"+ str(AS_PORT)
    # Next we locate the Spark installation - this will be found using the SPARK_HOME environment 
    # variable that you will have set 
    import findspark
    findspark.init(SPARK_HOME)
    # Aerospike Spark Connector related settings
    import os 
    AEROSPIKE_JAR_PATH= "aerospike-spark-assembly-"+AEROSPIKE_SPARK_JAR_VERSION+".jar"
    os.environ["PYSPARK_SUBMIT_ARGS"] = '--jars ' + SPARK_NB_DIR + '/' + AEROSPIKE_JAR_PATH + ' pyspark-shell'
    # imports
    import pyspark
    from pyspark.context import SparkContext
    from pyspark.sql.session import SparkSession
    from pyspark.sql.types import StructField, StructType, DoubleType
    
    sc = SparkContext.getOrCreate()
    conf=sc._conf.setAll([("aerospike.namespace",AS_NAMESPACE),("aerospike.seedhost",AS_CONNECTION_STRING)])
    sc.stop()
    sc = pyspark.SparkContext(conf=conf)
    spark = SparkSession(sc)

    # Load Model
    from pyspark.ml.classification import RandomForestClassificationModel

    rf_model = RandomForestClassificationModel.read().load(
        "/home/jovyan/notebooks/spark/resources/fs_model_rf")
    print("Loaded Random Forest model.")
    
    # Initialize model features and schema
    features = ["CC1_V"+str(i) for i in range(1,29)] # need features CC1_V1-CC1_V28
    schema = StructType()
    for i in range(1,29): # all features are of type float or Double
        schema.add("CC1_V"+str(i), DoubleType(), True)   
    return


if __name__ == '__main__':
    initialize()
    app.run(debug=True)
