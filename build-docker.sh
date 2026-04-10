#!/usr/bin/env bash
set -euo pipefail

# Build patched Debezium Server 3.5.0 Docker image from source.
#
# Builds JARs from the current tree (3.6.0-SNAPSHOT), renames them to
# 3.5.0.Final to overlay the base image, and tags the image as:
#   debezium-server:3.5.0-<short-git-hash>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ensure JAVA_HOME is set (try mise if available)
if [[ -z "${JAVA_HOME:-}" ]]; then
  if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
    export JAVA_HOME="$(mise where java)"
    export PATH="${JAVA_HOME}/bin:${PATH}"
  elif [[ -x "${HOME}/.local/bin/mise" ]]; then
    export JAVA_HOME="$("${HOME}/.local/bin/mise" where java)"
    export PATH="${JAVA_HOME}/bin:${PATH}"
  else
    echo "ERROR: JAVA_HOME is not set and mise is not available" >&2
    exit 1
  fi
fi

MVN="${SCRIPT_DIR}/mvnw"
OUTPUT_DIR="${SCRIPT_DIR}/lib/patch"
mkdir -p "${OUTPUT_DIR}"

# Get the Maven version from the root pom (e.g. 3.6.0-SNAPSHOT)
MVN_VERSION=$("${MVN}" -q -N help:evaluate -Dexpression=project.version -DforceStdout -f "${SCRIPT_DIR}/pom.xml")
TARGET_VERSION="3.5.0.Final"
GIT_HASH=$(git -C "${SCRIPT_DIR}" rev-parse --short HEAD)
IMAGE_TAG="debezium-server:3.5.0-${GIT_HASH}"

echo "Building from source version: ${MVN_VERSION}"
echo "Target version for image: ${TARGET_VERSION}"
echo "Image tag: ${IMAGE_TAG}"
echo ""

# Build the required modules (skip tests)
echo "==> Building JARs..."
"${MVN}" -f "${SCRIPT_DIR}/pom.xml" install -pl \
  debezium-util,debezium-config,debezium-connector-common,debezium-connector-oracle \
  -am -DskipTests -DskipITs -Dformat.skip -Dcheckstyle.skip

# Collect JARs: rename from source version to target version
# Format: "directory:artifact"
JARS=(
  "debezium-util:debezium-util"
  "debezium-config:debezium-config"
  "debezium-connector-common:debezium-connector-common"
  "debezium-connector-oracle:debezium-connector-oracle"
)

echo ""
echo "==> Collecting patch JARs..."
for entry in "${JARS[@]}"; do
  dir="${entry%%:*}"
  artifact="${entry##*:}"
  src="${SCRIPT_DIR}/${dir}/target/${artifact}-${MVN_VERSION}.jar"
  dst="${OUTPUT_DIR}/${artifact}-${TARGET_VERSION}.jar"
  if [[ ! -f "${src}" ]]; then
    echo "ERROR: ${src} not found" >&2
    exit 1
  fi
  cp "${src}" "${dst}"
  echo "  ${dst}"
done

# Build Docker image
echo ""
echo "==> Building Docker image..."
docker build -t "${IMAGE_TAG}" "${SCRIPT_DIR}"

echo ""
echo "Done: ${IMAGE_TAG}"
