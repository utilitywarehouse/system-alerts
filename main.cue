package alerts

import "encoding/yaml"

#env: {
	configMapName: *"alerts" | string
	disable:       _disable
	fileName:      *"all" | string
}

#data: #AlertGroupDataMapSchema

// Generates a map of all the groups and rules available, and defaults to false.
// To disable a group: `#env: disable: groups: <group_name>: true`
// To disable a rule: `#env: disable: rules: <group_name>: <rule_name>: true`
_disable: {
	groups: {
		for group in #data {
			"\( group.name )": *false | bool
		}
	}
	rules: {
		for group in #data {
			"\( group.name )": {
				for ruleName, rule in group.rules {
					"\( ruleName )": *false | bool
				}
			}
		}
	}
}

kube: {
	_groups: [...#AlertGroupSchema]
	_groups: [ for group in #data if !#env.disable.groups[group.name] {
		name: group.name
		rules: [ for ruleName, rule in group.rules if !#env.disable.rules[group.name][ruleName] {
			alert: ruleName
			labels: team: group.team
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
