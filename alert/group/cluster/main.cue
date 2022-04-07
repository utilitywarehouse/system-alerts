package cluster

#env: {
	provider:  string
	tier:      string
	team:      *"infra" | string
	groupName: *"cluster" | string
}

#data: {
	name: #env.groupName
	team: #env.team
	rules: {
		KubeletCadvisorNotResponding: {
			expr: *"up{job=\"kubernetes-nodes\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} ({{ $labels.role }}) has been down for more than 10 minutes."
				summary:     "Kubernetes node is down"
				dashboard:   "https://grafana.\(#env.tier)-\(#env.provider).uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&var-instance={{ $labels.instance }}&var-namespace=All&var-app=All&var-app_kubernetes_io_name=All"
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
				description: "{{ $labels.pod }} scheduler has been down for several minutes."
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
	}
}

alertGroup: #data
