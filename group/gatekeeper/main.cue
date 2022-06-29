package gatekeeper

#env: {
	provider:  string
	environment:      string
}

#data: {
	name: "gatekeeper"
	team: "infra"
	rules: {
		GatekeeperWebhookUnreachable: {
			expr: *"probe_success{job=\"gatekeeper-webhooks\"} == 0" | string
			for:  *"5m" | string
			annotations: {
				description: "{{ $labels.instance }} has been down for more than 5 minutes."
				summary:     "Gatekeeper webhook endpoint is not reachable."
			}
		}
		GatekeeperWebhookBlackboxTargetDown: {
			expr: *"up{job=\"gatekeeper-webhooks\"} != 1" | string
			for:  *"5m" | string
			annotations: {
				description: "{{ $labels.instance }} http probe job reports down more than 5 minutes."
				summary:     "Gatekeeper webhook http probe job down"
			}
		}
		GatekeeperWebhookErrors: {
			expr: *"sum without (instance) (rate(apiserver_admission_webhook_rejection_count{error_type!=\"no_error\",name=~\"^.*gatekeeper.sh$\"}[5m])) > 0" | string
			for:  *"1m" | string
			annotations: {
				description: """
					Admission requests were rejected by {{ $labels.name }} due to an error. This may indicate
					an issue with the service sys-gatekeeper/gatekeeper-webhook-service or the api server's
					ability to reach that endpoint.

					"""

				summary: "Gatekeeper webhook {{ $labels.name }} has errors"
			}
		}
		GatekeeperViolations: {
			expr: *"gatekeeper_violations > 0" | string
			annotations: {
				description: """
					The gatekeeper audit has identified violations in the cluster.

					You can inspect violations with this command:
					`kubectl --context=\(#env.environment)-\(#env.provider) get constraint -o json | jq '.items[] | select(.status.totalViolations != 0) | .status.violations'`

					"""

				summary: "Gatekeeper violations detected"
			}
		}
	}
}

alertGroup: #data
