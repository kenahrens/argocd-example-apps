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
REPLAY_NAME="${6:-$BUILD_TAG}"

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

# Wait until the report is complete
REPORT_ID=$(speedctl wait report --tag $BUILD_TAG --id-only --timeout 10m)
REPORT=$(speedctl get report $REPORT_ID)
STATUS=$(echo $REPORT | jq .report.status)
echo "Report: https://app.speedscale.com/report/${REPORT_ID}"
echo "Traffic Replay Status: $STATUS"

# Cleanup the traffic replay CR
# git rm $DEST_FILE
# git commit -m "Cleaning up $DEST_FILE"
# git push origin master

# Sync it with argo to clean up
# argocd app sync podtato --prune
