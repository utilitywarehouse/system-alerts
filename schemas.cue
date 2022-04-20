package alerts

#AlertGroupSchema: {
	name: string
	rules: [...#RuleSchema]
}

// Adapted from "github.com/prometheus/prometheus/model/rulefmt"'s `Rule`
// and "github.com/prometheus/common/model"'s `durationRE`
#RuleSchema: {
	alert?: string @go(Alert)
	#RuleDataSchema
}

#AlertGroupDataMapSchema: [groupName=_]: {
	name: groupName
	team: string
	rules: [_]: #RuleDataSchema
}

// Separated from #RuleSchema, since "alert" is inferred by it's map key
#RuleDataSchema: {
	record?: string                                                                                               @go(Record)
	expr:    string                                                                                               @go(Expr)
	for?:    string & =~"^(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?$" // added manually
	labels?: {[string]: string} @go(Labels,map[string]string)
	annotations?: {[string]: string} @go(Annotations,map[string]string)
}
