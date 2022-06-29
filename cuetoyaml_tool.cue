package alerts

import (
	"encoding/yaml"
	"tool/cli"

	//"group/aws"
	//"group/cluster"
	//"group/etcd"
	//"group/externalDNS"
	//"group/gatekeeper"
	//"group/gcp"
	//"group/kubeApplier"
	//"group/kyverno"
	//"group/logging"
	//"group/matchbox"
	//"group/nat"
	//"group/netapp"
	//"group/semaphore"
	//"group/terraformApplier"
	//"group/thanos"
	//"group/tlsProbe"
	//"group/vault"
	//"group/wiresteward"
	//"group/workload"

	//"github.com/utilitywarehouse/system-alerts:alerts"
	"github.com/utilitywarehouse/system-alerts/group/aws"
	//"github.com/utilitywarehouse/system-alerts/group/cluster"
	//"github.com/utilitywarehouse/system-alerts/group/etcd"
	//"github.com/utilitywarehouse/system-alerts/group/externalDNS"
	//"github.com/utilitywarehouse/system-alerts/group/kubeApplier"
	//"github.com/utilitywarehouse/system-alerts/group/kyverno"
	//"github.com/utilitywarehouse/system-alerts/group/logging"
	//"github.com/utilitywarehouse/system-alerts/group/matchbox"
	//"github.com/utilitywarehouse/system-alerts/group/nat"
	//"github.com/utilitywarehouse/system-alerts/group/semaphore"
	//"github.com/utilitywarehouse/system-alerts/group/terraformApplier"
	//"github.com/utilitywarehouse/system-alerts/group/tlsProbe"
	//"github.com/utilitywarehouse/system-alerts/group/thanos"
	//"github.com/utilitywarehouse/system-alerts/group/vault"
	//"github.com/utilitywarehouse/system-alerts/group/workload"
)

_cm_env: {configMapName: "alerts", fileName: "infra"}
_env: {provider: "local", environment: "dev"}

_aws: aws & {#env: _env}
_data: "\(_aws.alertGroup.name)": _aws.alertGroup

_alerts: {#data: _data} & {#env: _cm_env}

command: build: {
	task: print: cli.Print & {
		text: yaml.MarshalStream(objects)
	}
}

objects: [ for kind in kube for object in kind {object}]
