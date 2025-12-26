# Debezium Fork

This is a forked development branch. Build instructions below are specific to this fork.

## Build

```bash
make help   # Show available commands
make build  # Build Oracle connector + Docker image
```

## Docker Image

- Base: `quay.io/debezium/connect:3.3.2.Final`
- Output: `debezium/connect:<git describe --tags>`
- Replaces Oracle connector JAR with local build
