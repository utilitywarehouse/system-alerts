package workload

#env: {
	provider:  string
	tier:      string
	namespace: *"~\"kube-system|sys-.*\"" | string
	team:      *"infra" | string
	groupName: *"\(team)-workload" | string
	owner:     *"system" | string
}

#data: {
	name: #env.groupName
	team: #env.team
	rules: {
		DaemonsetMissingReplicas: {
			expr: *"kube_daemonset_status_number_ready{namespace=\(#env.namespace)} != kube_daemonset_status_desired_number_scheduled{namespace=\(#env.namespace)}" | string
			for:  *"15m" | string
			annotations: summary: "{{ $labels.daemonset }} daemonset in {{ $labels.namespace }} namespace has missing replicas for 15m"
		}
		DeploymentMissingReplicas: {
			expr: *"kube_deployment_status_replicas_available{namespace=\(#env.namespace)} != kube_deployment_status_replicas{namespace=\(#env.namespace)}" | string
			for:  *"15m" | string
			annotations: summary: "{{ $labels.deployment }} deployment in {{ $labels.namespace }} namespace has missing replicas for 15m"
		}
		StatefulsetMissingReplicas: {
			expr: *"kube_statefulset_status_replicas_ready{namespace=\(#env.namespace)} != kube_statefulset_status_replicas{namespace=\(#env.namespace)}" | string
			for:  *"15m" | string
			annotations: summary: "{{ $labels.statefulset }} statefulset in {{ $labels.namespace }} namespace has missing replicas for 15m"
		}
		PodOOMing: {
			expr: *"rate(kube_pod_container_status_terminated_reason{reason=\"OOMKilled\",namespace=\(#env.namespace)}[15m]) != 0" | string
			annotations: {
				summary:   "Pod {{ $labels.namespace }}/{{ $labels.pod }} has OOMed in last 15 minutes."
				impact:    "{{$labels.pod}} service might not be working as expected."
				action:    "Investigate memory consumption and adjust pods resources."
				dashboard: "https://grafana.\(#env.tier)-\(#env.provider).uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&from=now-12h&to=now&var-instance=All&var-namespace={{ $labels.namespace }}"
			}
		}
		PodRestartingOften: {
			expr: *"increase(kube_pod_container_status_restarts_total{namespace=\(#env.namespace)}[10m]) > 3" | string
			annotations: {
				summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has restarted more than 3 times in the last 10m"
				impact:  "{{$labels.pod}} may not be working as expected."
				action:  "Check the pod logs to figure out the issue"
			}
		}
		// https://github.com/kubernetes-monitoring/kubernetes-mixin/issues/108#issuecomment-432796867
		PodContainerCpuThrottled: {
			expr: *"sum(increase(container_cpu_cfs_throttled_periods_total{namespace=\(#env.namespace)}[5m])) by (container, pod, namespace) / sum(increase(container_cpu_cfs_periods_total{namespace=\(#env.namespace)}[5m])) by (container, pod, namespace) > 0.95" | string
			for:  *"15m" | string
			annotations: {
				summary:   "{{ $labels.namespace }}/{{ $labels.pod }}/{{ $labels.container }} is being CPU throttled."
				impact:    "{{ $labels.namespace }}/{{ $labels.pod }} might take longer than normal to respond to requests."
				action:    "Investigate CPU consumption and adjust pods resources if needed."
				dashboard: "https://grafana.\(#env.tier)-\(#env.provider).uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&from=now-12h&to=now&var-instance=All&var-namespace={{ $labels.namespace }}"
			}
		}
		VolumeDiskUsage: {
			expr: *"kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"\(#env.owner)\"} > 0.9" | string
			for:  *"5m" | string
			annotations: {
				summary:   "Volume {{ $labels.namespace }}/{{ $labels.persistentvolumeclaim }} has less than 10% available capacity"
				impact:    "Exhausting available disk space will most likely result in service disruption"
				action:    "Investigate disk usage and adjust volume size if necessary."
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/919b92a8e8041bd567af9edab12c840c/kubernetes-persistent-volumes?orgId=1&refresh=10s&var-datasource=default&var-cluster=&var-namespace={{ $labels.namespace }}&var-volume={{ $labels.persistentvolumeclaim }}"
			}
		}
	}
}

alertGroup: #data
