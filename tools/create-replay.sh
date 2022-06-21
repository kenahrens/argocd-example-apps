#!/usr/bin/env bash

set -eof pipefail

function Usage() {
    cat <<EOM
##### Create & run traffic replay for an app using ArgoCD

Required arguments:
    -d | --dest-dir          A path where traffic replay manifest should
                             be added to
    -w | --workload-name     A name of the workload to run replay for
    -s | --snapshot-id       Traffic snapshot identifier

Optional arguments:
    -t | --test-config-id    Test config id to be used with the replay. Defaults
                             to standard
    -b | --build-tag         A build tag to be used with the replay, e.g. CI job
                             identifier or git commit hash
    -n | --replay-name       A name of the replay to be created. Defaults to
                             build tag
    -h | --help              Show this message and exit

Requirements:
    speedctl:                Speedscale CLI https://speedscale.com/cli-download/

Example:
    create-replay.sh \\
        -d podtato \\
        -w podtato-head-entry \\
        -s 41a06065-ec28-438a-b9f4-0e976c6f64ca
EOM
    exit 127
}

function Require {
    command -v $1 > /dev/null 2>&1 || {
        echo "Some of the required software is not installed: $1"
        exit 1;
    }
}

# show usage if no args provided
if [[ $# == 0 ]] ; then Usage; fi

# validate requirements
Require speedctl

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dest-dir)
        DEST_DIR="${2}"
        shift
        ;;
    -w|--workload-name)
        WORKLOAD_NAME="${2}"
        shift
        ;;
    -s|--snapshot-id)
        SNAPSHOT_ID="${2}"
        shift
        ;;
    -b|--build-tag)
        BUILD_TAG="${2}"
        shift
        ;;
    -t|--test-config-id)
        TEST_CONFIG_ID="${2}"
        shift
        ;;
    -n|--name)
        REPLAY_NAME="${2}"
        shift
        ;;
    -h|--help)
        Usage
        ;;
    *)
        echo "Unknown argument: ${1}. Pass -h or --help to see usage"
        exit 3
        ;;
  esac
  shift
done

BASE_DIR="$(dirname ${BASH_SOURCE[0]})"
SRC_FILE=${BASE_DIR}/replay-template.yaml

# validate input
if [[ -z ${DEST_DIR} ]]; then
    echo "Destination directory is required"
    exit 2
fi

if [[ -z ${WORKLOAD_NAME} ]]; then
    echo "Workload name is required"
    exit 2
fi

if [[ -z ${SNAPSHOT_ID} ]]; then
    echo "Snapshot id is required"
    exit 2
fi

# set defaults
EPOCH=$(date +%s)
BUILD_TAG=${BUILD_TAG:-$EPOCH}
TEST_CONFIG_ID="${TEST_CONFIG_ID:-standard}"
REPLAY_NAME="${REPLAY_NAME:-$BUILD_TAG}"

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
argocd app sync podtato --prune

# Wait until the report is complete
REPORT_ID=$(speedctl wait report --tag $BUILD_TAG --id-only --timeout 10m)
REPORT=$(speedctl get report $REPORT_ID)

# Cleanup the traffic replay CR
git rm $DEST_FILE
git commit -m "Cleaning up $DEST_FILE"
git push origin master

# Sync it with argo (again)
argocd app sync podtato --prune

# Print the results
echo "Report: https://app.speedscale.com/report/${REPORT_ID}"

SUCCESS=$(echo $REPORT | jq -c '.report.aggregates[] | select(.name | contains("passAssertPct")) | .gaugeVal.val')
AVG_LATENCY=$(echo $REPORT | jq -c '.report.aggregates[] | select(.name | contains("avgLatency")) | .gaugeVal.val')
STATUS=$(echo $REPORT | jq .report.status)

echo "Success Rate:           ${SUCCESS}%"
echo "Average Latency:        ${AVG_LATENCY}ms"
echo "Traffic Replay Status:  $STATUS"
