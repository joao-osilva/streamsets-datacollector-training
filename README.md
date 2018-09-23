# Streamsets Data Collector - Training
> By: João Silva (vitor191291@gmail.com)

## Setup
### Install Docker and Docker Compose


### MySQL Server
- Check whether the container is up and running:

  `$ docker ps | grep mysql`

- The first time you spin up MySQL you need to change the default password and create a new user that is enable to access the server remotely. Execute the script to do this:

  `$ ./mysql_setup.sh`

- The script will create a user `sdc` with password `sdc`

### Apache Kafka
- Create a topic to store pipeline errors:

  `$ docker exec -ti kafka-1 bash -c "kafka-topics --create --zookeeper zookeeper-1:22181,zookeeper-2:32181,zookeeper-3:42181 --replication-factor 3 --partitions 3 --topic datacollector-errors --if-not-exists"``


### Streamsets Data Collector
- Login to Data Collector at `http://localhost:18630` with user/pass `admin:admin`

  ![sql_driver_1](https://i.imgur.com/io4efEV.png)

**Configure MySQL JDBC driver**
- Download the driver and [here](https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.zip) and extract the folder

- Go to *Package Manager* -> *External Libraries*, upload the driver and restart Data Collector:

  ![sql_driver_1](https://i.imgur.com/lwIQNAo.png)
  ![sql_driver_2](https://i.imgur.com/VteFwQN.png)
  ![sql_driver_3](https://i.imgur.com/FE1GeJG.png)
  ![sql_driver_4](https://i.imgur.com/h7vot7J.png)
  ![sql_driver_5](https://i.imgur.com/k7waJ58.png)

## Cases
### 1)Streaming Apache server logs to Elasticsearch
#### Create index
- Go to Kibana at `http://localhost:5601` and login with user/pass `elastic:changeme`

  ![kibana_index_1](https://i.imgur.com/sZo1nQe.png)

- Go to *Dev Tools* and create an index using the mapping below:

  ```json
  {
    "mappings": {
      "log": {
        "properties": {
          "timestamp": {
            "type": "date"
          },
          "verb": {
            "type": "keyword"
          },
          "clientip": {
            "type": "keyword"
          },
          "response": {
            "type": "keyword"
          },
          "request": {
            "type": "keyword"
          },
          "bytes": {
            "type": "long"
          }
        }
      }
    }
  }
  ```

  ![kibana_index_2](https://i.imgur.com/9p2XPXy.png)

- After the index is created, go to *Management* -> *Index Patterns* and create a new index pattern named "apache_logs":

  ![kibana_index_3](https://i.imgur.com/X2AcN5Z.png)

  ![kibana_index_4](https://i.imgur.com/xJvw54T.png)

#### Create a new pipeline
- Add a **File Tail** origin and configure the file path and pattern:

  ![apache_log_watcher_1](https://i.imgur.com/H1bVVxP.png)

  ![apache_log_watcher_2](https://i.imgur.com/CUIUo7E.png)

  ![apache_log_watcher_3](https://i.imgur.com/h486uiW.png)

- Add a **Field Remover** processor and remove some fields(/auth, /ident, /rawrequest, /httpversion):

  ![apache_log_watcher_4](https://i.imgur.com/IVi3ulm.png)

- Add a **Field Type Converter** processor and convert "/bytes" to LONG and "/timestamp" to ZONED_DATETIME:

  ![apache_log_watcher_5](https://i.imgur.com/zvHa6rl.png)

  ![apache_log_watcher_6](https://i.imgur.com/VGIY2sq.png)

- Add an **Elasticsearch** destination, enter the server info, credentials and index/mapping information:

  ![apache_log_watcher_7](https://i.imgur.com/xGcUGkI.png)

  ![apache_log_watcher_8](https://i.imgur.com/nLOAE1s.png)

  ![apache_log_watcher_9](https://i.imgur.com/5l5kC57.png)

- Start the pipeline and observe the metrics:

  ![apache_log_watcher_10](https://i.imgur.com/rn40XIR.png)

#### Create an analytical dashboard in Kibana
- Go back to *Management* -> *Index Patterns*, select the "apache_logs" index and click *refresh*. The columns "searchable" and "aggregatable" should be marked now:

  ![kibana_dash_1](https://i.imgur.com/wrnydER.png)

- Import [this](asd) dashboard by going to *Dashboard* -> *Open* -> *Manage Dashboards* -> *Import*:

  ![kibana_dash_2](https://i.imgur.com/ZizVfgb.png)

  ![kibana_dash_3](https://i.imgur.com/lE8t9Tj.png)

- Go back to *Dashboards* -> *Open* and select "apache_log_dashboard":

  ![kibana_dash_4](https://i.imgur.com/oQnZa3F.png)

- Now you can visually monitor you apache log metrics in real time:
  ![kibana_dash_5](https://i.imgur.com/K4OQppO.png)

### 2)Monitor file ingestion
#### Create a topic for the errors
- The pipeline will send all records with error to the topic("pipeline-errors"), so we can analyze it later:

  `$ docker exec -it kafka-1 bash -c "kafka-topics --create --zookeeper zookeeper-1:22181,zookeeper-2:32181,zookeeper-3:42181 --replication-factor 3 --partitions 3 --topic pipeline-errors --if-not-exists"`

- Check whether the topic was created:

  ```sh
  $ docker exec -ti kafka-1 bash -c "kafka-topics --list --zookeeper zookeeper-1:22181,zookeeper-2:32181,zookeeper-3:42181"
  __confluent.support.metrics
  __consumer_offsets
  pipeline-errors
  ```

#### Query documents on MongoDB
- Now you can take a look at the geoip collection and its documents:

  ```
  $ docker exec -it mongodb bash -c "mongo geoip --quiet --eval 'db.geoip.find().limit(5)'"

  { "_id" : ObjectId("5ba71b62149b3f003551258a"), "json" : "{\"clientip\":\"199.72.81.55\",\"lat\":37.751,\"lon\":-97.822}" }
  { "_id" : ObjectId("5ba71b62149b3f003551258b"), "json" : "{\"clientip\":\"199.120.110.21\",\"lat\":37.751,\"lon\":-97.822}" }
  { "_id" : ObjectId("5ba71b62149b3f003551258c"), "json" : "{\"clientip\":\"199.120.110.21\",\"lat\":37.751,\"lon\":-97.822}" }
  { "_id" : ObjectId("5ba71b62149b3f003551258d"), "json" : "{\"clientip\":\"205.212.115.106\",\"lat\":37.751,\"lon\":-97.822}" }
  { "_id" : ObjectId("5ba71b62149b3f003551258e"), "json" : "{\"clientip\":\"129.94.144.152\",\"lat\":-33.6994,\"lon\":150.9536}" }
  ````
