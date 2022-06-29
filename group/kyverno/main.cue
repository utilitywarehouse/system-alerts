package kyverno

#env: {
	provider:  string
	environment:      string
}

#data: {
	name: "kyverno"
	team: "infra"
	rules: {
		KyvernoBackgroundCheckRuleFailure: {
			expr: *"increase(kyverno_policy_results_total{rule_execution_cause=\"background_scan\", rule_result=\"fail\"}[1h]) > 0" | string
			annotations: {
				description: """
                                        Background checks for rule: {{ $labels.rule_name }} of policy: {{ $labels.policy_name }}
                                        report failures under {{ $labels.resource_namespace }} namespace.

                                        To get more info about the issue check the namespace events with the following command:
                                        `kubectl --context={{ $labels.kubernetes_cluster }} -n {{ $labels.resource_namespace }} get events`
                                        """
				summary: "Kyverno policy: {{ $labels.policy_name }} rule: {{ $labels.rule_name }} is failing in {{ $labels.resource_namespace }} namespace."
                                dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/Rg8lWBG7k/kyverno"
			}
		}
	}
}

alertGroup: #data
