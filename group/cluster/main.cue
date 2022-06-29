package cluster

#env: {
	provider:  string
	environment:      string
}

#data: {
	name: "cluster"
	team: "infra"
	rules: {
		KubeletCadvisorNotResponding: {
			expr: *"up{job=\"kubernetes-nodes\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} ({{ $labels.role }}) has been down for more than \(for)."
				summary:     "Kubernetes node is down"
				dashboard:   "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&var-instance={{ $labels.instance }}&var-namespace=All&var-app=All&var-app_kubernetes_io_name=All"
			}
		}
		KubernetesApiDown: {
			expr: *"up{service=\"kubernetes\"} != 1" | string
			for:  *"1m" | string
			annotations: {
				description: "The kubernetes API is down within the cluster."
				summary:     "Kubernetes API server is down"
			}
		}
		KubernetesSchedulerDown: {
			expr: *"up{service=\"kube-scheduler\"} != 1" | string
			for:  *"5m" | string
			annotations: {
				description: "{{ $labels.pod }} scheduler has been down for \(for)."
				summary:     "Kubernetes scheduler {{ $labels.pod }} is down"
			}
		}
		KubeStateMetricsAbsent: {
			expr: *"absent(kube_state_metrics_build_info)" | string
			for:  *"5m" | string
			annotations: {
				description: "A number of our critical alerts depend on the metrics produced by kube-state-metrics."
				summary:     "Metrics from kube-state-metrics are absent"
			}
		}
		NodeNotReady: {
			expr: *"count(kube_node_info) - count(kube_node_status_condition{condition=\"Ready\", status=\"true\"}) != 0" | string
			for:  *"5m" | string
			annotations: {
				description: "One or more of the worker nodes in the cluster is marked as Not Ready."
				summary:     "Kubernetes node is Not Ready"
			}
		}
		NodeUnschedulable: {
			expr: *"count(kube_node_spec_unschedulable == 1) > 0" | string
			for:  *"1h" | string
			annotations: {
				description: "One or more of the nodes in the cluster is marked as unschedulable."
				summary:     "Kubernetes cluster has unschedulable node(s)"
			}
		}
		NodeNoDiskSpace: {
			expr: *"kube_node_status_condition{condition=\"OutOfDisk\", status=\"true\"} != 0" | string
			for:  *"2m" | string
			annotations: {
				description: "{{ $labels.node }} is reporting that it is out of disk space."
				summary:     "node {{ $labels.node }} has no disk space"
			}
		}
		KubernetesLowNodeMemory: {
			expr: *"sum(node_memory_MemAvailable{kubernetes_role=\"node\"}) BY (instance) < 1.073741824e+09" | string
			for:  *"5m" | string
			annotations: {
				description: "{{ $labels.instance }} is reporting low free memory of {{ .Value | humanize1024 }}B."
				summary:     "Kubernetes node low memory"
				value:       "{{ $value }}"
			}
		}
		ReadOnlyRootFilesystem: {
			expr: *"ro_rootfs != 0" | string
			for:  *"5m" | string
			annotations: summary: "{{ $labels.instance }} instance has a read only root filesystem for \(for)"
		}
		CfsslDown: {
			expr: *"probe_success{job=\"cfssl-probe\"} == 0 or absent(probe_success{job=\"cfssl-probe\"})" | string
			for:  *"5m" | string
			annotations: summary: "{{ $labels.instance }} reports down more than \(for)."
		}
		CertExpireK8SSidecarInjector: {
			expr: *"(probe_ssl_earliest_cert_expiry{job=\"k8s-sidecar-injector-tls-probe\"} - time()) / 60 / 60 / 24 < 7" | string
			for:  *"5m" | string
			annotations: {
				summary:   "The k8s-sidecar-injector-webhook certificate will expire in < 7 days"
				impact:    "APIServer will not be able to talk to k8s-sidecar-injector and applications will not have sidecars injected"
				action:    "Short term: restart k8s-sidecar-injector Deployment. Long term: Make sure k8s-sidecar-injector reloads certificate/key when they change on disk"
				dashboard: "https://thanos-query-sys-prom.\(#env.environment).\(#env.provider).uw.systems/graph?g0.expr=(probe_ssl_earliest_cert_expiry%7Bjob%3D%22k8s-sidecar-injector-tls-probe%22%7D%20-%20time())%20%2F%2060%20%2F%2060%20%2F%2024&g0.tab=0&g0.stacked=0&g0.range_input=1d&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D"
			}
		}
	}
}

alertGroup: #data
