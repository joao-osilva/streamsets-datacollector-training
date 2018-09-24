# Streamsets Data Collector - Training
> By: João Silva (vitor191291@gmail.com)

This training aims to show some cool features that Streamsets Data Collector has and how one can levarage them in real scenarios.

The applications used were:
  - Streamsets Data Collector 3.4.3
  - MySQL Server 5.7
  - MongoDB 3.6.8
  - Apache Cassandra 3.11.3
  - Elasticsearch 5.2.0
  - Kibana 5.2.0
  - Apache Zookeeper(Confluent Platform) 5.0.0
  - Apache Kafka(Confluent Platform) 5.0.0
  - Portainer

The training topics are:
- [Setup](#setup)
- [Cases](#cases)
  - [Streaming Apache server logs to Elasticsearch](#streaming-apache-server-logs-to-elasticsearch)
  - [Monitoring file ingestion](#monitoring-file-ingestion)
  - [Analyze logs as time series](#analyze-logs-as-time-series)

## Setup
#### Install Docker and Docker Compose
- Just follow the instructions based on you OS, [Docker](https://www.docker.com/get-started) and [Docker Compose](https://docs.docker.com/compose/install/)

#### Build Data Collector's docker image and spin up composer
- There is a custom Dockerfile under "streamsets/" that we need to build first:

  `$ docker build --no-cache -t semantix/data-collector-training:1.0.0 streamsets/`

- Now we can run the docker-compose file with all the containers:

  `$ docker-compose up -d`

#### Use Portainer to manage containers
- Go to `http://localhost:9000` and check whether the containers are up and running, under *Primary* -> *Containers*:

  ![portainer_1](https://i.imgur.com/EeZdiVs.png)

  ![portainer_2](https://i.imgur.com/K3Gxknb.png)

  ![portainer_3](https://i.imgur.com/QhhC8L7.png)

#### MySQL Server
- Check whether the container is up and running:

  `$ docker ps | grep mysql`

- The first time you spin up MySQL you need to change the default password and create a new user that is enable to access the server remotely. Execute the script to do this:

  `$ ./mysql_setup.sh`

- The script will create a user `sdc` with password `sdc`

#### Apache Cassandra
- Create a keyspace/table so we can use later:

  `$ docker exec -it cassandra bash -c "cqlsh -f /root/cassandra_setup.txt"`

#### Apache Kafka
- Create a topic to store pipeline errors:

  `$ docker exec -ti kafka-1 bash -c "kafka-topics --create --zookeeper zookeeper-1:22181,zookeeper-2:32181,zookeeper-3:42181 --replication-factor 3 --partitions 3 --topic datacollector-errors --if-not-exists"`


#### Streamsets Data Collector
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
### Streaming Apache server logs to Elasticsearch
#### Create a log file
- In order to simulate a constantly growing apache log we are going to use the "Fake Apache Log Generator" script. So you'll need to have python installed on your OS, and then you can just follow the steps on theirs [github page](https://github.com/kiritbasu/Fake-Apache-Log-Generator).

- Copy the "apache-fake-log-gen.py" script to "streamsets-datacollector-training/streamsets/resources":

  ![fake_log_1](https://i.imgur.com/wTitKrA.png)

- Execute the script to generate the log:

  `$ python <path>/streamsets-datacollector-training/streamsets/resources/apache-fake-log-gen.py -n 0 -o LOG -p WEB`

  **OBS:** "-n 0" is to generate an infinite log file, "-o LOG" is the output type, "-p WEB" is the file prefix.

- You should the file on the directory:

    ![fake_log_2](https://i.imgur.com/IvCG2zw.png)

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
- Add a **File Tail** origin and set the file path to "/home/sdc/resources/WEB_access_log_*.log" and the data format to "Log":

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

### Monitoring file ingestion
#### Download the data file and the Geo IP database:
- Download the data file [here](http://ita.ee.lbl.gov/traces/NASA_access_log_Jul95.gz), and the Geo IP database [here](http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz)

- Uncompress the **GeoLite2-City.mmdb.gz** file and place both(and **NASA_access_log_Jul95.gz**) at "/streamsets-datacollector-training/streamsets/resources" folder.

- This folder is mapped to the container's "/home/sdc/resources" folder, that we are going to use later in the pipeline.

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

#### Create a new pipeline
- Add a **Directory** origin and configure the files directory, pattern and the data format:

  ![file_ingestion_monitor_1](https://i.imgur.com/RTAM0FQ.png)

  ![file_ingestion_monitor_2](https://i.imgur.com/yrtQe7n.png)

- Add a **Expression Evaluator** processor and create an output field that checks whether the "clientip" attribute matches the regex("((\\d){1,3}\\.){3}(\\d){1,3}":

  ![file_ingestion_monitor_3](https://i.imgur.com/FxBWfbN.png)

- Add a **Stream Selector** processor and configure it to send the record to condition 1 in case the "clientip" attribute is not well formatted, or to condition 2 in case it is:

  ![file_ingestion_monitor_4](https://i.imgur.com/QAyhvw5.png)

- Add a **To Error** destination to send the mal-formatted record to the previously created topic("pipeline-errors"):

  ![file_ingestion_monitor_5](https://i.imgur.com/sKQA51d.png)

- Add a **Geo IP** processor to retrieve the latitude and longitude for the given clientip, based on a lib. Set the database file to "/home/sdc/resources/GeoLite2-City.mmdb":

  ![file_ingestion_monitor_6](https://i.imgur.com/j0a9PAb.png)

- Add a **Expression Evaluator** processor to create a map with all attributes(clientip, lat and lon), and add a header attribute named "sdc.operation.type" with value "1" in order to inform MongoDB that we are doing an insert:

  ![file_ingestion_monitor_7](https://i.imgur.com/rncEgkK.png)

- Add a **JSON Generator** processor to convert our map to JSON:

  ![file_ingestion_monitor_8](https://i.imgur.com/dByA5dL.png)

- Add a **Field Remover** processor to keep only our JSON field and drop the remaining ones:

  ![file_ingestion_monitor_9](https://i.imgur.com/x3oWUun.png)

- Add a **MongoDB** destination and set the Database/Collection to "geoip" and Unique Key Field to "clientip". OBS: MongoDB is very smart, so no need to create the db/collection prior :) :

  ![file_ingestion_monitor_10](https://i.imgur.com/4E7Eg9M.png)

#### Configure the destination for records with error:
- Go to the pipeline configuration at the *Error Records* tab and select "Write to Kafka" on *Error Records*:

  ![file_ingestion_monitor_17](https://i.imgur.com/TLdZXpt.png)

- Now go to the *Error Records - Write to Kafka* tab and set the *Broker URI* to "kafka-1:29092" and *Topic* to our previously created "pipeline errors":

  ![file_ingestion_monitor_18](https://i.imgur.com/kHbBnFJ.png)

#### Configure some pipeline metrics/alerts:
- Go to the pipeline configuration at the *Rules* -> *Metric Rules* tab, and click on *Edit* at the "Pipeline Error Records Counter" *Metric ID*:

  ![file_ingestion_monitor_11](https://i.imgur.com/u4wBKGI.png)

- Configure it to send an alert when the number of erros pass the 1000 mark, select the "Send Email" flag and click "Save". After that select the *Active* flag at the line:

  ![file_ingestion_monitor_12](https://i.imgur.com/5ogbpGO.png)

  ![file_ingestion_monitor_13](https://i.imgur.com/tzhwWCe.png)

- Go to the *Notifications* tab and add an email address that should be notified by the alert:

  ![file_ingestion_monitor_14](https://i.imgur.com/3OJymMt.png)

- Now start the pipeline and watch the metrics go up, you should see an alert popup when the number of errors hit 1000. You'll also receive an email about the alert:  

  ![file_ingestion_monitor_15](https://i.imgur.com/1FE1Wzi.png)

  ![file_ingestion_monitor_16](https://i.imgur.com/aBCerdu.png)


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

### Analyze logs as time series
#### Create a new pipeline
- Add a **Kafka Consumer** origin and set the *Broker URI* to "kafka-1:29092", *Zookeeper URI* to "zookeeper-1:23888,zookeeper-2:33888,zookeeper-3:43888", *Topic* to "pipeline-errors", *Max Batch Size (records)* to 500 and Kafka's *auto.offset.reset* to "earliest". On *Data format* tab set to SDC Record:

  ![error_topic_consumer_1](https://i.imgur.com/jnnPKVQ.png)

  ![error_topic_consumer_2](https://i.imgur.com/x2Yr4iw.png)

  ![error_topic_consumer_3](https://i.imgur.com/KCyQ9bJ.png)

- Add a **Field Type Converter** processor to cast the timestamp:

  ![error_topic_consumer_4](https://i.imgur.com/CEnZWTp.png)

- Add a **Field Remover** processor to remove unnecessary fields:

  ![error_topic_consumer_5](https://i.imgur.com/CITiXLR.png)

- Add a **Cassandra** destination and set *Max Batch Size* on *General* tab to 500. On *Cassandra* tab set the *Fully Qualified Table Name* to "streamsets.pipeline_errors" and map the record fields to their respective table columns:

  ![error_topic_consumer_9](https://i.imgur.com/h58VDKD.png)

  ![error_topic_consumer_6](https://i.imgur.com/uZ6WOET.png)

  ![error_topic_consumer_7](https://i.imgur.com/0eJt9u3.png)

- Start the pipeline and observe the metrics:  

  ![error_topic_consumer_8](https://i.imgur.com/XDaicv5.png)

#### Query records on Cassandra
- Now you can take a look at the errors stored as time series using the time when they occurred:

  ```
  $ docker exec -it cassandra bash -c "cqlsh -e 'SELECT * FROM streamsets.pipeline_errors LIMIT 10;'"

  event_time                      | ip                        | url
  --------------------------------+---------------------------+---------------------------------------------------
  1995-07-01 04:00:25.000000+0000 |  waters-gw.starway.net.au |          /shuttle/missions/51-l/mission-51-l.html
  1995-07-01 04:00:35.000000+0000 |     ppp-mia-30.shadow.net |                        /images/ksclogo-medium.gif
  1995-07-01 04:00:18.000000+0000 | ppptky391.asahi-net.or.jp |                             /facts/about_ksc.html
  1995-07-01 04:00:14.000000+0000 |      unicomp6.unicomp.net |                      /shuttle/countdown/count.gif
  1995-07-01 04:00:12.000000+0000 |        burger.letters.com |                        /images/NASA-logosmall.gif
  1995-07-01 04:00:15.000000+0000 |               d104.aa.net |                      /shuttle/countdown/count.gif
  1995-07-01 04:00:59.000000+0000 |       ppp-nyc-3-1.ios.com | /shuttle/missions/sts-71/images/KSC-95EC-0882.jpg
  1995-07-01 04:00:50.000000+0000 |    gayle-gaston.tenet.edu |      /shuttle/missions/sts-71/mission-sts-71.html
  1995-07-01 04:00:41.000000+0000 |     ppp-mia-30.shadow.net |                               /shuttle/countdown/
  ```
