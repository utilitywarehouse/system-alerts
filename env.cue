package alerts

#env: {
	configMapName: *"alerts-\(fileName)" | string
	disable:       _disable
	fileName:      *"alerts" | string
}

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
