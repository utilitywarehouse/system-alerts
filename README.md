Contains alerts templates under a single base

# Available alert bases

- common: Contains templates for alerts we deploy everywhere
- cis-aws: Contains templates for alerts based on CIS Benchmark for AWS
- kube-applier: Contains templates for kube-applier alerts

# Patch thanos-rule deployment

We need to patch thanos ruler to add an init container that will render alerts
from the templates and put them in a volume for thanos-rule container. The base
to do that can be found [here](./thanos-rule-template).

# Environment variables

The following environment variables are used and expected to be patched
downstream:

- ENVIRONMENT: exp-1|dev|prod
- PROVIDER: aws|gcp|merit

# How to use it

Bases need to be included as `components` in the local base to be evaluated
after the resources of the parent kustomization (overlay or component) have been
accumulated. This is to be able to successfully identify and patch thanos-rule
deployment that will be coming from a different remote base. Note that
`thanos-rule-template` base should always be included. For example:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
components:
  - github.com/utilitywarehouse/system-alerts/thanos-rule-template?ref=master # Patch thanos-rule to render alerts
  # Include the needed alerts
  - github.com/utilitywarehouse/system-alerts/cis-aws?ref=master
  - github.com/utilitywarehouse/system-alerts/common?ref=master
  - github.com/utilitywarehouse/system-alerts/kube-applier?ref=master

patches:
  - path: thanos-rule-init.yaml
```

Then patch the initContainer with the needed environment variables:

```
$ cat thanos-rule-init.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thanos-rule
spec:
  template:
    spec:
      initContainers:
        - name: render-alerts
          env:
            - name: ENVIRONMENT
              value: exp-1
            - name: PROVIDER
              value: aws
```

# How to add new bases

When adding a new base one should create a configMap with the needed templates
and must patch thanos-rule to mount the configMap under
`/var/thanos/rule-templates/<base-name>` directory.
Note that volume names must follow the pattern:
- `rule-templates-<base-name>`
and mount points should follow the pattern:
- `/var/thanos/rule-templates/<base-name>`
to make sure that volumes from different bases do not clash.
