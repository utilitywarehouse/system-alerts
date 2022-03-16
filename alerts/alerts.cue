package alerts

_alertGroups: infra: {
	_input: kube.#input

	name: "infra"
	rules: [{
		alert: "AWSNoMFAConsoleSignin"
		expr:  "cisbenchmark_sane_no_mfaconsole_signin_sum >= 1"
		for:   "1m"
		labels: {
			team:          "infra"
			send_resolved: "false"
		}
		annotations: {
			description: "A user or users signed into the AWS console without MFA enabled"
			summary:     "AWS console login without MFA detected"
			action: "Identify the users in question from the Cloudtrail logs, disable their account and notify the user."
			logs: "https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logEventViewer:group=cloudtrail-multi-region;filter=%257B%2520(%2524.eventName%2520%253D%2520%2522ConsoleLogin%2522)%2520%2526%2526%2520(%2524.additionalEventData.MFAUsed%2520%2521%253D%2520%2522Yes%2522)%2520%2526%2526%2520(%2524.responseElements.ConsoleLogin%2520%253D%2520%2522Success%2522)%2520%257D;start=PT1H"
		}
	}, {
		alert: "AWSRootUsage"
		expr:  "cisbenchmark_root_usage_sum >= 1"
		for:   "1m"
		labels: {
			team:          "infra"
			send_resolved: "false"
		}
		annotations: {
			description: "Cloudtrail logs show activity for the root user"
			summary:     "AWS root account usage detected"
			action: """
				Identify the activity in the Cloudtrail logs. Verify if the activity is legitimate. If not, change
				the root user password, MFA and any access keys immediately. Contact
				AWS support in the case of complete lock out.
				"""
			logs: "https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logEventViewer:group=cloudtrail-multi-region;filter=%257B%2520%2524.userIdentity.type%2520%253D%2520%2522Root%2522%2520%2526%2526%2520%2524.userIdentity.invokedBy%2520NOT%2520EXISTS%2520%2526%2526%2520%2524.eventType%2521%253D%2520%2522AwsServiceEvent%2522%2520%257D;start=PT1H"
		}
	}, {
		alert: "KubeletCadvisorNotResponding"
		expr:  "up{job=\"kubernetes-nodes\"} != 1"
		for:   "10m"
		labels: team: "infra"
		annotations: {
			description:
				"{{ $labels.instance }} ({{ $labels.role }}) has been down for more than 10 minutes."
			summary:   "Kubernetes node is down"
			dashboard: "https://grafana.\(_input.env)-\(_input.provider).uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&var-instance={{ $labels.instance }}&var-namespace=All&var-app=All&var-app_kubernetes_io_name=All"
		}
	}, {
		alert: "KubernetesApiDown"
		expr:  "up{service=\"kubernetes\"} != 1"
		for:   "1m"
		labels: team: "infra"
		annotations: {
			description: "The kubernetes API is down within the cluster."
			summary:     "Kubernetes API server is down"
		}
	}, {
		alert: "KubernetesSchedulerDown"
		expr:  "up{service=\"kube-scheduler\"} != 1"
		for:   "5m"
		labels: team: "infra"
		annotations: {
			description: "{{ $labels.pod }} scheduler has been down for several minutes."
			summary:     "Kubernetes scheduler {{ $labels.pod }} is down"
		}
	}, {
		alert: "KubeStateMetricsAbsent"
		expr:  "absent(kube_state_metrics_build_info)"
		for:   "5m"
		labels: team: "infra"
		annotations: {
			description: "A number of our critical alerts depend on the metrics produced by kube-state-metrics."
			summary:     "Metrics from kube-state-metrics are absent"
		}
	}, {
		alert: "NodeNotReady"
		expr:
			"count(kube_node_info) - count(kube_node_status_condition{condition=\"Ready\", status=\"true\"}) != 0"

		for: "5m"
		labels: team: "infra"
		annotations: {
			description:
				"One or more of the worker nodes in the cluster is marked as Not Ready."

			summary: "Kubernetes node is Not Ready"
		}
	}, {
		alert: "NodeUnschedulable"
		expr:  "count(kube_node_spec_unschedulable == 1) > 0"
		for:   "1h"
		labels: team: "infra"
		annotations: {
			description: "One or more of the nodes in the cluster is marked as unschedulable."
			summary:     "Kubernetes cluster has unschedulable node(s)"
		}
	}, {
		alert: "NodeNoDiskSpace"
		expr:  "kube_node_status_condition{condition=\"OutOfDisk\", status=\"true\"} != 0"
		for:   "2m"
		labels: team: "infra"
		annotations: {
			description: "{{ $labels.node }} is reporting that it is out of disk space."
			summary:     "node {{ $labels.node }} has no disk space"
		}
	}, {
		alert: "KubernetesLowNodeMemory"
		expr:  "sum(node_memory_MemAvailable{kubernetes_role=\"node\"}) BY (instance) < 1.073741824e+09"
		for:   "5m"
		labels: team: "infra"
		annotations: {
			description:
				"{{ $labels.instance }} is reporting low free memory of {{ .Value | humanize1024 }}B."

			summary: "Kubernetes node low memory"
			value:   "{{ $value }}"
		}
	}, {
		alert: "SystemDaemonsetMissingReplicas"
		expr:  "kube_daemonset_status_number_ready{namespace=~\"kube-system|sys-.*\"} != kube_daemonset_status_desired_number_scheduled{namespace=~\"kube-system|sys-.*\"}"
		for:   "15m"
		labels: team: "infra"
		annotations: summary: "{{ $labels.daemonset }} daemonset in {{ $labels.namespace }} namespace has missing replicas for 15m"
	}, {
		alert: "SystemDeploymentMissingReplicas"
		expr:  "kube_deployment_status_replicas_available{namespace=~\"kube-system|sys-.*\"} != kube_deployment_status_replicas{namespace=~\"kube-system|sys-.*\"}"
		for:   "15m"
		labels: team: "infra"
		annotations: summary: "{{ $labels.deployment }} deployment in {{ $labels.namespace }} namespace has missing replicas for 15m"
	}, {
		alert: "SystemStatefulsetMissingReplicas"
		expr:  "kube_statefulset_status_replicas_ready{namespace=~\"kube-system|sys-.*\"} != kube_statefulset_status_replicas{namespace=~\"kube-system|sys-.*\"}"
		for:   "15m"
		labels: team: "infra"
		annotations: summary: "{{ $labels.statefulset }} statefulset in {{ $labels.namespace }} namespace has missing replicas for 15m"
	}, {
		alert: "SystemPodOOMing"
		expr:  "rate(kube_pod_container_status_terminated_reason{reason=\"OOMKilled\",namespace=~\"kube-system|sys-.*\"}[15m]) != 0"
		labels: team: "infra"
		annotations: {
			summary:   "Pod {{ $labels.namespace }}/{{ $labels.pod }} has OOMed in last 15 minutes."
			impact:    "{{$labels.pod}} service might not be working as expected."
			action:    "Investigate memory consumption and adjust pods resources."
			dashboard: "https://grafana.exp-1-aws.uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&from=now-12h&to=now&var-instance=All&var-namespace={{ $labels.namespace }}"
		}
	}, {
		alert: "SystemPodRestartingOften"
		expr:  "increase(kube_pod_container_status_restarts_total{namespace=~\"kube-system|sys-.*\"}[10m]) > 3"
		labels: team: "infra"
		annotations: {
			summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has restarted more than 3 times in the last 10m"
			impact:  "{{$labels.pod}} may not be working as expected."
			action:  "Check the pod logs to figure out the issue"
		}
	}, {
		// https://github.com/kubernetes-monitoring/kubernetes-mixin/issues/108#issuecomment-432796867
		alert: "PodContainerCpuThrottled"
		expr:  "sum(increase(container_cpu_cfs_throttled_periods_total{namespace=~\"kube-system|sys-.*\"}[5m])) by (container, pod, namespace) / sum(increase(container_cpu_cfs_periods_total{namespace=~\"kube-system|sys-.*\"}[5m])) by (container, pod, namespace) > 0.95"
		for:   "15m"
		labels: team: "infra"
		annotations: {
			summary:   "{{ $labels.namespace }}/{{ $labels.pod }}/{{ $labels.container }} is being CPU throttled."
			impact:    "{{ $labels.namespace }}/{{ $labels.pod }} might take longer than normal to respond to requests."
			action:    "Investigate CPU consumption and adjust pods resources if needed."
			dashboard: "https://grafana.exp-1-aws.uw.systems/d/VAE0wIcik/kubernetes-pod-resources?orgId=1&refresh=1m&from=now-12h&to=now&var-instance=All&var-namespace={{ $labels.namespace }}"
		}
	}, {
		alert: "ReadOnlyRootFilesystem"
		expr:  "ro_rootfs != 0"
		for:   "5m"
		labels: team: "infra"
		annotations: summary: "{{ $labels.instance }} instance has a read only root filesystem for 5m"
	}, {
		alert: "CfsslDown"
		expr:  "probe_success{job=\"cfssl-probe\"} == 0 or absent(probe_success{job=\"cfssl-probe\"})"
		for:   "5m"
		labels: team: "infra"
		annotations: summary: "{{ $labels.instance }} reports down more than 5 minutes."
	}, {
		alert: "VolumeDiskUsage"
		expr:  "kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"system\"} > 0.9"
		for:   "5m"
		labels: team: "infra"
		annotations: {
			summary:   "Volume {{ $labels.namespace }}/{{ $labels.persistentvolumeclaim }} has less than 10% available capacity"
			impact:    "Exhausting available disk space will most likely result in service disruption"
			action:    "Investigate disk usage and adjust volume size if necessary."
			dashboard: "https://grafana.exp-1.aws.uw.systems/d/919b92a8e8041bd567af9edab12c840c/kubernetes-persistent-volumes?orgId=1&refresh=10s&var-datasource=default&var-cluster=&var-namespace={{ $labels.namespace }}&var-volume={{ $labels.persistentvolumeclaim }}"
		}
	}, {
		alert: "CertExpireK8SSidecarInjector"
		expr:  "(probe_ssl_earliest_cert_expiry{job=\"k8s-sidecar-injector-tls-probe\"} - time()) / 60 / 60 / 24 < 7" // Less then a week
		for:   "5m"
		labels: team: "infra"
		annotations: {
			summary:   "The k8s-sidecar-injector-webhook certificate will expire in < 7 days"
			impact:    "APIServer will not be able to talk to k8s-sidecar-injector and applications will not have sidecars injected"
			action:    "Short term: restart k8s-sidecar-injector Deployment. Long term: Make sure k8s-sidecar-injector reloads certificate/key when they change on disk"
			dashboard: "https://thanos-query-sys-prom.exp-1.aws.uw.systems/graph?g0.expr=(probe_ssl_earliest_cert_expiry%7Bjob%3D%22k8s-sidecar-injector-tls-probe%22%7D%20-%20time())%20%2F%2060%20%2F%2060%20%2F%2024&g0.tab=0&g0.stacked=0&g0.range_input=1d&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D"
		}
	}]
}
