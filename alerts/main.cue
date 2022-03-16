package alerts

import "encoding/yaml"

kube: {
	#input: {
		env:      string // prod, dev exp-1...
		provider: string // aws, gcp, merit...
		additionalGroups: [...#AlertGroup] // accept additional groups if format is correct
	}

	_groups: [...#AlertGroup] // ensure all groups are valid #AlertGroup
	_groups: [ for alertGroup in _alertGroups {alertGroup & {_input: #input}}] + #input.additionalGroups

	configMap: alerts: {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: name:     "alerts"
		data: "infra.yaml": yaml.Marshal({groups: _groups})
	}
}

#AlertGroup: {
  name: string
	rules: [...#Rule]
	rules: [...{
    labels: team: string
  }]
}

// Adapted from "github.com/prometheus/prometheus/model/rulefmt"'s `Rule`
// and "github.com/prometheus/common/model"'s `durationRE`
#Rule: {
	record?: string @go(Record)
	alert?:  string @go(Alert)
	expr:    string @go(Expr)
	for?:    string & =~"^(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?$" // added manually
	labels?: {[string]: string} @go(Labels,map[string]string)
	annotations?: {[string]: string} @go(Annotations,map[string]string)
}
