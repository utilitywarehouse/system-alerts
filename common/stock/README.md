# Stock alerts
Common and useful alerts maintained by @system and readily available for teams
to consume.

## Usage
Stock alerts are already setup and "firing" for all namespaces. Teams only need
to claim namespace oncall responsibility to receive them.

To do so, add a `uw.systems/oncall-team` **annotation** (not label!) to
namespaces to claim them, and the team will receive the stock alerts for those
namespaces automatically.

Namespace definitions live in
`kubernetes-manifests/<cluster>/kube-system/namespaces.yaml` or in
`kubernetes-manifests/<cluster>/<namespace>/00-namespaces.yaml`, depending on
whether they use ArgoCD or Kube-Applier for automatic deployment. 

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

### Note on alert grouping
If your team is using a custom grouping that is missing entries from the
default grouping (set at the top of the [alertmanager
config](https://github.com/utilitywarehouse/kubernetes-manifests/blob/master/prod-aws/sys-mon/resources/alertmanager-config-template.yaml#L12)), it is suggested to configure stock alerts to use the stock grouping:
```
route:
  ...
  routes:
    ...
    - matchers: ['{team="myteam"}']
      receiver: myteam-receiver
      routes:
        # Example of specifying grouping for stock alerts, using the yaml alias
        - matchers: ['{alerttype="stock"}']
          group_by: *stock_grouping
    ...
```
