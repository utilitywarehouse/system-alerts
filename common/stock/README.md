# Stock alerts
Common and useful alerts maintained by @system and readily available for teams
to consume.

## Usage
Stock alerts are already setup and "firing" for all teams, and they only need
to be consumed by teams, if they choose to.

To consume the alerts, there are 2 options:
* Opt into automatic team detection based on namespace owner (recommended)
* Create a new alertmanager route to manually consume alerts for whatever
  namespace you care about

### Automatic team detection based on `uw.systems/owner` namespace label
Stock alerts can generate a `team` label with the value of the
`uw.systems/owner` label of the namespace that the alert belongs to.

To opt-in into this team detection, add your `uw.systems/owner` value to the
regex at the end of
https://github.com/utilitywarehouse/system-alerts/blob/main/common/stock/team_detection.yaml#L10.
Ask in #infra if you need help setting this up.

Now the stock alerts for your namespaces will have a `team` label and be
captured by your existing router.

### Manual configuration of specific namespaces
Add a new route on alertmanager filtering your namespaces and pointing to your
receiver. The `matchers` clause follows the usual prometheus syntax.

Example:
```
route:
  ...
  routes:
    ...
    - matchers: ['{alerttype="stock", namespace=~"myteam-.*|alsoimportant"}']
      receiver: myteam-receiver
    ...
```

### Note on grouping alerts
Stock alerts use the default grouping found at the top of the [alertmanager
config](https://github.com/utilitywarehouse/kubernetes-manifests/blob/master/prod-aws/sys-mon/resources/alertmanager-config-template.yaml#L12)

If your team alerts need different grouping, you can configure it by adding a
subroute for your alerts with your custom grouping:
```
route:
  ...
  routes:
    ...
    - matchers: ['{team="myteam"}']
      receiver: myteam-receiver
      routes:
        # Example of custom grouping for non-stock alerts
        - matchers: ['{alerttype!="stock"}']
          group_by: ["your", "custom", "grouping"]
    ...
```

### Opting out of some alerts
If you want to opt out of some alerts, you can have a subroute matching what
you don't want and sending it to the `deadletter` receiver.

Example ignoring some alerts:
```
route:
  ...
  routes:
    ...
    - matchers: ['{team="myteam"}']
      receiver: myteam-receiver
      routes:
        # Example of ignoring some alerts by sending them to `deadletter`
        - matchers: ['{alertgroup="storage"}']
          receiver: deadletter
        # Example of ignoring some alerts by sending them to `deadletter`
        - matchers: ['{alertname="StatefulSetMissingReplicas",statefulset="kafka"}']
          receiver: deadletter
    ...
```

## Notes for @system

### Note on `namespace` vs `kubernetes_namespace` labels
There are two possible "namespace" labels in metrics
* `namespace` is the namespace labeled by a metric inside it's exporter. It is
  relevant in metrics exposed by workloads that are aware of kubernetes
  namespace as a concept, like metrics coming from argocd or
  kube-state-metrics.
* `kubernetes_namespace` is the namespace where the metric was scraped from.
  This is relevant in metrics exposed by workloads that do not deal with
  kubernetes namespaces as a concept.

Currently all the metrics used in the stock alerts rely only on `namespace` label, but this may change in the future. We could either add a second matcher or relabel `kubernetes_namespace` to `namespace` in all metrics where `namespace` is not set.

### Note for @system team configuration
There are metrics that have a @system `kubernetes_namespace` but a non-@system
`namespace`, like an argocd metric that comes from a @system namespace but is
talking about another team's namespace (`argocd_app_info{sync_status!="Synced",
kubernetes_namespace="sys-argo-cd", namespace="billing"} 1`).

However, there are no metrics that have a @system `namespace` but a non-@system
`kubernetes_namespace`. This can be verified by running `group by (__name__)
({namespace=~"kube-system|sys-.*",
kubernetes_namespace!~"|kube-system|sys-.*"})` and getting no results.

For this reasons, @system needs to be more careful with it's matchers and ensure
it's not catching team's metrics by accident.
