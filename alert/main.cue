package alert

import "encoding/yaml"

kube: {
	_groups: [...#AlertGroupSchema]
	_groups: [ for group in #data if !#env.disable.groups[group.name] {
		name: group.name
		rules: [ for rule in group.rules if !#env.disable.rules[group.name][rule.alert] {
			rule
		}]
	}]

	configMap: "\(#env.configMapName)": {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: name:                "\(#env.configMapName)"
		data: "\(#env.fileName).yaml": yaml.Marshal({groups: _groups})
	}
}
