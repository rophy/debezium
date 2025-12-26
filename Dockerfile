FROM quay.io/debezium/connect:3.3.2.Final

# Replace only the connector JAR (dependencies stay the same)
USER root
RUN rm /kafka/connect/debezium-connector-oracle/debezium-connector-oracle-*.jar
COPY --chown=kafka:kafka \
     debezium-connector-oracle/target/debezium-connector-oracle-*.jar \
     /kafka/connect/debezium-connector-oracle/
USER kafka
