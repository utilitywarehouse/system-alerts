# Stock alerts
Common and useful alerts maintained by @system and readily available for teams
to consume.

## Usage
Stock alerts are already setup and "firing" for all teams, and they only need
to be consumed by teams, if they choose to.

To consume the stock alerts, add a new route on alertmanager filtering your
namespaces and pointing to your receiver. The `matchers` clause follows the
usual prometheus syntax.

Example (with recommended grouping):
```
route:
  routes:
    - matchers: ['{namespace=~"myteam-.*"}']
      receiver: myteam-receiver
      group_by: ["alertname", "namespace", "deployment", "statefulset"]
```

If you want to opt out of some alerts, you can have a subroute matching what
you don't want and sending it to the `deadletter` receiver.

Example ignoring some alerts:
```
route:
  routes:
    - matchers: ['{namespace=~"myteam-.*"}']
      receiver: myteam-receiver
      group_by: ["alertname", "namespace", "deployment", "statefulset"]
      routes:
        # Example of ignoring some alerts by sending them to `deadletter`
        - matchers: ['{alertname="StatefulSetMissingReplicas",statefulset="kafka"}']
          receiver: deadletter
```

## Note on `team` label and catching-non-stock alerts
Matchers filtering only by namespace can also match team's own alerts, which
could be undesired. If you need different configuration for stock alerts and
your team dedicated alerts, you need to tweak the filters.

Example of different routes for stock and team alerts(assuming team alerts use
`team` label):
```
route:
  routes:
    - matchers: ['{namespace=~"myteam-.*", team=""}']
      receiver: myteam-receiver-for-stock-alerts
      ...
    - matchers: ['{team="myteam"}']
      receiver: myteam-receiver-for-team-alerts
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
