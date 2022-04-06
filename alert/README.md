# Alerts
This package provides a configmap with alerts to be used by prometheus.

## File structure
* `data.cue`: constraints for the `#data` definition
* `env.cue`: `#env` definition of the "environmental variables" supported
* `main.cue`: exported fields
* `schemas.cue`: definitions for schemas, providing validation
* `*-data.cue`: alert group values
* `alertGroups/`: collection of alert groups values

## Usage
The configmap is exported as usual via a "kube" field.

The configurable definitions are:
* `#env`: environmental variables to be used by the alerts defined inside this package. Also used to disable specific groups or alerts
* `#data`: a map of the alert groups that will be added to the configmap. It can be used to modify the default data and to provide additional groups (like the ones inside `alertGroups/`)

## Example
A main.cue file making use of this package could look like:

```
package kube

// import this package and two addional alert groups
import (
	"github.com/utilitywarehouse/system-cue/alert"
	"github.com/utilitywarehouse/system-cue/alert/group/aws"
	"github.com/utilitywarehouse/system-cue/alert/group/etcd"
)

// define environment
_env: {provider: "aws", tier: "exp-1"}

// "instantiate" groups with the local environment
_aws: aws & {#env: _env}
_etcd: etcd & {#env: _env}

// build the _data map with the additional groups, using the group name as key
_data: "\(_aws.alertGroup.name)": _aws.alertGroup
_data: "\(_etcd.alertGroup.name)": _etcd.alertGroup

// if needed, edit some group's data, like relaxing some alert threshold in dev
//_data: myEtcdAlertGroup: rules: ETCDMemberCommunicationSlow: expr: "mymetric > 0.1"

// "instantiate" the alert package, providing the environment and the additional groups
_alert: alert & {#env: _env} & {#data: _data}

// if needed, disable some group or alert
//_alert: alert & {#env: disable: groups: myEtcdAlertGroup: true
//_alert: alert & {#env: disable: rules: myEtcdAlertGroup: ETCDMemberCommunicationSlow: true

// add the alert's kube to the main `kube` field
kube: _alert.kube
```

# ToDo
* add label with team
```
#AlertGroup: {
  name: string
	rules: [...#Rule]
	rules: [...{
    labels: team: string
  }]
}
//#AlertModuleMap: [ID=_]: {
//	#enabled: *true | false
//	alert:    ID
//	labels: {team: string, send_resolved: *"true" | "false"}
//}
```
