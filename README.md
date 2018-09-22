# Streamsets Data Collector - Training
> By: João Silva (vitor191291@gmail.com)

## Setup
### MySQL Server
- Check whether the container is up and running:

  `$ docker ps | grep mysql`

- The first time you spin up MySQL you need to change the default password and create a new user that is enable to access the server remotely. Execute the script to do this:

  `$ ./mysql_setup.sh`

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
### Streaming Apache log to Elasticsearch
- Create an index/mapping:

  ```
  $ curl -X PUT -u elastic:changeme -H "Content-Type: application/json" 'http://localhost:9200/apache_logs'
  -d '{"mappings": {
          "log": {
            "properties": {
              "timestamp": {
                "type": "date"
              },
              "verb": {
                "type": "text"
              },
              "clientip": {
                "type": "text"
              },
              "response": {
                "type": "text"
              },
              "request": {
                "type": "text"
              },
              "bytes": {
                "type": "long"
              }
            }
          }
        }}'
  ```

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

- asd

  ![apache_log_watcher_5]()
