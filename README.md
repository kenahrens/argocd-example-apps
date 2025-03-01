# ArgoCD Example Apps

This repository contains example applications for demoing ArgoCD functionality. Feel free
to register this repository to your ArgoCD instance, or fork this repo and push your own commits
to explore ArgoCD and GitOps!

| Application | Description |
|-------------|-------------|
| [guestbook](guestbook/) | A hello word guestbook app as plain YAML |
| [podtato](podtato/) | CNCF example app as plain YAML |

## Tools

The create-replay shell script can be used to run a replay on a workload and sync with argo. This can be kicked off from this example script:

```
./tools/create-replay.sh \
  --dest-dir DEST_DIR \
  --workload-name WORKLOAD_NAME \
  --snapshot-id SNAPSHOT_ID \
  --test-config-id TEST_CONFIG_ID \
  --build-tag BUILD_TAG \
  --replay-name REPLAY_NAME
```

These are the values:
* **DEST_DIR** - where you want to create the traffic replay CR
* **WORKLOAD_NAME** - what workload does the traffic replay run against
* **SNAPSHOT_ID** - what traffic snapshot to use
* **BUILD_TAG** - what build hash to use (will use current time epoch if not supplied)
* **TEST_CONFIG_ID** - what test config to use (will use standard if not supplied)
* **REPLAY_NAME** - what replay name to use (will use `$BUILD_TAG` if not supplied)

### Deploy podtato

How to deploy podtato in your argo:

```
argocd app create podtato \
--repo https://github.com/kenahrens/argocd-example-apps.git \
--path podtato \
--dest-server https://kubernetes.default.svc \
--dest-namespace default
```

How to run a replay:

```
./tools/create-replay.sh \
  --dest-dir podtato \
  --workload-name podtato-head-entry \
  --snapshot-id 41a06065-ec28-438a-b9f4-0e976c6f64ca
```

As it's running you will see it creates the CR, checks it in and syncs argo, and then waits for the test report to be complete. You should see it print this kind of output at the end:

```
...
Report: https://app.speedscale.com/report/f8e765a8-ba55-4aa4-ab80-f1a4f8906524
Success Rate:           100%
Average Latency:        2.572151898734177ms
Traffic Replay Status:  "Passed"
```