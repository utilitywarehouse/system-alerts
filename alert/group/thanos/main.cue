package thanos

#env: {
	provider:  string
	tier:      string
	team:      *"infra" | string
	groupName: *"thanos" | string
}

#data: {
	name: #env.groupName
	team: #env.team
	rules: {
		ThanosCompactHalted: {
			expr: *"thanos_compactor_halted{app=\"thanos-compact\",kubernetes_namespace=~\"sys-.*\"} == 1" | string
			annotations: {
				summary:   "Thanos compaction has failed to run and now is halted"
				impact:    "Long term storage queries will be slower"
				action:    "Check {{ $labels.kubernetes_pod_name }} pod logs in {{ $labels.kubernetes_namespace}} namespace"
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/s48S7j4ik/thanos-compaction"
			}
		}
		ThanosCompactCompactionsFailed: {
			expr: *"rate(prometheus_tsdb_compactions_failed_total{app=\"thanos-compact\",kubernetes_namespace=~\"sys-.*\"}[5m]) > 0" | string
			annotations: {
				summary:   "Thanos Compact is failing compaction"
				impact:    "Long term storage queries will be slower"
				action:    "Check {{ $labels.kubernetes_pod_name }} pod logs in {{ $labels.kubernetes_namespace}} namespace"
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/s48S7j4ik/thanos-compaction?refresh=30s&orgId=1&var-interval=1m&var-namespace={{$labels.kubernetes_namespace}}&var-labelselector=app&var-labelvalue=thanos-compact"
			}
		}
		ThanosSidecarPrometheusDown: {
			expr: *"thanos_sidecar_prometheus_up{name=\"prometheus\",kubernetes_namespace=~\"sys-.*\"} == 0" | string
			for:  *"10m" | string
			annotations: {
				summary:   "Thanos Sidecar cannot connect to Prometheus"
				impact:    "Prometheus configuration is not being refreshed"
				action:    "Check {{ $labels.kubernetes_pod_name }} pod logs in {{ $labels.kubernetes_namespace}} namespace"
				dashboard: "https://grafana.\(#env.tier)-\(#env.provider).uw.systems/d/IOteEKHik/thanos-sidecar?refresh=30s&orgId=1&var-interval=1m&var-labelvalue=prometheus&var-namespace={{$labels.kubernetes_namespace}}&var-labelselector=name"
			}
		}
		ThanosRuleBadConfig: {
			expr: *"min(thanos_rule_config_last_reload_successful{app=\"thanos-rule\",kubernetes_namespace=~\"sys-.*\"}) == 0" | string
			for:  *"10m" | string
			annotations: {
				summary:   "Thanos Rule failed to load alert config"
				impact:    "On Thanos Rule restart alerts wont be loaded."
				action:    "Ask in slack for any alert changes and check {{ $labels.kubernetes_pod_name }} pod logs in {{ $labels.kubernetes_namespace}} namespace"
				dashboard: "https://grafana.\(#env.tier)-\(#env.provider).uw.systems/d/rjUCNfHmz/thanos-rule?refresh=30s&orgId=1&var-interval=1m&var-namespace={{ $labels.kubernetes_namespace}}&var-labelselector=app&var-labelvalue=thanos-rule"
			}
		}
	}
}

alertGroup: #data
