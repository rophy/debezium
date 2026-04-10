FROM quay.io/debezium/server:3.5.0.Final

# 3.5.0.Final is missing debezium-config (dbz#1779).
# The following JARs are rebuilt from source to include fixes:
#   - DBZ-9615: LOB savepoint rollback fix
#   - dbz#1801: Oracle RAC archive log dedup fix
#
# Usage:  ./build-docker.sh
COPY --chown=jboss:jboss lib/patch/*.jar /debezium/lib/
