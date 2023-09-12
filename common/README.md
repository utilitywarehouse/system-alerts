# Stock alerts
These are alerts prepared by @system to be used by all teams.

## Usage
To use the stock alerts, use a matcher on a label that filters your team
resources, currently the relevant ones are `namespace` and
`kubernetes_namespace`.

If you want to opt out of some alerts, you can have a subroute matching what
you don't want and sending it to the `deadletter` receiver.

Example alertmanager example:
```
route:
  routes:
    - receiver: myTeam
      matchers: ['{namespace=~"myTeam-.*"}']
      group_by: [ ... ]
      routes:
        # Example of ignoring some alerts by sending them to `deadletter`
        - matchers: ['{group="container"}']
          receiver: deadletter
        - matchers: ['{alertname="DaemonsetMissingReplicas",statefulset="kafka"}']
          receiver: deadletter
    - receiver: myTeam
      matchers: ['{kubernetes_namespace=~"myTeam-.*"}']
      group_by: [ ... ]
```

## Note on `namespace` vs `kubernetes_namespace` labels
* `namespace` is the namespace labeled by a metric inside it's exporter. It is
  relevant in metrics exposed by workloads that are aware of kubernetes
  namespace as a concept, like metrics coming from argocd or
  kube-state-metrics.
* `kubernetes_namespace` is the namespace where the metric was scraped from.
  This is relevant in metrics exposed by workloads that do not deal with
  kubernetes namespaces as a concept.

There are metrics that have a @system `kubernetes_namespace` but a non-@system
`namespace`, like an argocd metric that comes from a @system namespace but is
talking about another team's namespace (`argocd_app_info{sync_status!="Synced",
kubernetes_namespace="sys-argo-cd", namespace="billing"} 1`).

However, there are no metrics that have a @system `namespace` but a non-@system
`kubernetes_namespace`. This can be verified by running `group by (__name__)
({namespace=~"kube-system|sys-.*",
kubernetes_namespace!~"|kube-system|sys-.*"})` and getting no results.

For this reasons, @system needs to be more careful with it's matches and ensure
it's not catching team's metrics by accident.
