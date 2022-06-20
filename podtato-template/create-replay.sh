#! /bin/bash

BASE_DIR=$(dirname $0)
SRC_FILE=${BASE_DIR}/replay-template.yaml

# Required inputs
DEST_DIR="${1}"
WORKLOAD_NAME="${2}"
SNAPSHOT_ID="${3}"

# These inputs have default values
EPOCH=$(date +%s)
BUILD_TAG="${4:-$EPOCH}"
TEST_CONFIG_ID="${5:-standard}"
REPLAY_NAME="${6:-$EPOCH}"

# Start doing substitutions
DEST_FILE=${DEST_DIR}/replay-${REPLAY_NAME}.yaml

echo "Creating template "
echo "Source:      $SRC_FILE"
echo "Dest:        $DEST_FILE"
echo "Workload:    $WORKLOAD_NAME"
echo "Snapshot:    $SNAPSHOT_ID"
echo "Build Tag:   $BUILD_TAG"
echo "Test Config: $TEST_CONFIG_ID"
echo "Replay Name: $REPLAY_NAME"

cat ${SRC_FILE} | sed \
  -e "s/WORKLOAD_NAME/${WORKLOAD_NAME}/" \
  -e "s/SNAPSHOT_ID/${SNAPSHOT_ID}/" \
  -e "s/BUILD_TAG/${BUILD_TAG}/" \
  -e "s/TEST_CONFIG_ID/${TEST_CONFIG_ID}/" \
  -e "s/REPLAY_NAME/${REPLAY_NAME}/" \
  > $DEST_FILE

# Add to git
git add $DEST_FILE
git commit -m "Adding $DEST_FILE"
git push origin master

# Sync it with argo
argocd app sync podtato

# Check it with speedctl
# speedctl get report 

# Cleanup the traffic replay CR
# git rm $DEST_FILE
# git commit -m "Cleaning up $DEST_FILE"
# git push origin master