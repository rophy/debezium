#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Build Oracle connector JAR
./mvnw clean install -pl debezium-connector-oracle -am -DskipTests

# Build Docker image
TAG=$(git describe --tags)
docker build -t debezium/connect:$TAG .
