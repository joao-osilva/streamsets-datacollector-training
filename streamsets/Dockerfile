FROM streamsets/datacollector:3.4..3

# Build time argument to install packages
ARG PACKAGES_TO_INSTALL=streamsets-datacollector-elasticsearch_5-lib,streamsets-datacollector-apache-kafka_0_11-lib,streamsets-datacollector-aws-lib,streamsets-datacollector-apache-solr_6_1_0-lib,streamsets-datacollector-apache-kudu_1_7-lib,streamsets-datacollector-groovy_2_4-lib,streamsets-datacollector-jdbc-lib,streamsets-datacollector-jms-lib,streamsets-datacollector-jython_2_7-lib,streamsets-datacollector-mongodb_3-lib,streamsets-datacollector-cassandra_3-lib,streamsets-datacollector-google-cloud-lib,streamsets-datacollector-bigtable-lib,streamsets-datacollector-rabbitmq-lib

# Install the packages
RUN if [[ ! -z $PACKAGES_TO_INSTALL ]]; then $SDC_DIST/bin/streamsets stagelibs -install=$PACKAGES_TO_INSTALL ; fi