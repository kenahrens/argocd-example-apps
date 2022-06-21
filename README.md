# ArgoCD Example Apps

This repository contains example applications for demoing ArgoCD functionality. Feel free
to register this repository to your ArgoCD instance, or fork this repo and push your own commits
to explore ArgoCD and GitOps!

| Application | Description |
|-------------|-------------|
| [guestbook](guestbook/) | A hello word guestbook app as plain YAML |
| [podtato](podtato/) | CNCF example app as plain YAML |

## Tools

The create-replay shell script can be used to run a replay on a workload and sync with argo.

```
./tools/create-replay.sh /
  DEST_DIR /
  WORKLOAD_NAME /
  SNAPSHOT_ID /
  BUILD_TAG /
  TEST_CONFIG_ID /
  REPLAY_NAME
```

These are the values:
* DEST_DIR - where you want to create the traffic replay CR
* WORKLOAD_NAME - what workload does the traffic replay run against
* SNAPSHOT_ID - what traffic snapshot to use
* BUILD_TAG - what build hash to use (will use epoch if not supplied)
* TEST_CONFIG_ID - what test config to use (will use standard if not supplied)
* REPLAY_NAME - what replay name to use (will use $BUILD_TAG if not supplied)

### Deploy podtato

```
argocd app create podtato \
--repo https://github.com/kenahrens/argocd-example-apps.git \
--path podtato \
--dest-server https://kubernetes.default.svc \
--dest-namespace default
```