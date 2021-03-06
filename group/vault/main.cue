package vault

#env: {
	provider:  string
	tier:      string
}

#data: {
	name: "vault"
	team: "infra"
	// Recommendations from https://s3-us-west-2.amazonaws.com/hashicorp-education/whitepapers/Vault/Vault-Consul-Monitoring-Guide.pdf
	rules: {
		VaultHighGCDuration: {
			expr: *"increase(vault_runtime_total_gc_pause_ns{kubernetes_namespace=\"sys-vault\"}[1m])/ 1000 > 2000" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.kubernetes_pod_name }} spent more than 2sec/min running GC"
				summary:     "{{ $labels.kubernetes_pod_name }} is taking too long to GC"
				dashboard:   "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/1ysHZE2Wz/vault"
			}
		}
		VaultScarceLeaderContacts: {
			expr: *"vault_raft_leader_lastContact{quantile=\"0.99\",kubernetes_namespace=\"sys-vault\"} > 0.2" | string
			for:  *"20m" | string
			annotations: {
				description: "{{ $labels.kubernetes_pod_name }} leader is taking more than 200ms to contact"
				summary:     "{{ $labels.kubernetes_pod_name }} contact with leader degraded"
				dashboard:   "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/1ysHZE2Wz/vault"
			}
		}
		// Adapted from https://github.com/giantswarm/vault-exporter/blob/master/vault-mixin/alerts.libsonnet
		VaultUninitialized: {
			expr: *"vault_initialized{kubernetes_namespace=\"sys-vault\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: "This may indicate an issue with the 'initializer' sidecar"
				summary:     "{{ $labels.kubernetes_pod_name }} is uninitialized"
				dashboard:   "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/1ysHZE2Wz/vault"
			}
		}
		VaultSealed: {
			expr: *"vault_sealed{kubernetes_namespace=\"sys-vault\"} != 0" | string
			for:  *"10m" | string
			annotations: {
				description: "This may indicate an issue with the 'unsealer' sidecar"
				summary:     "{{ $labels.kubernetes_pod_name }} is sealed"
				dashboard:   "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/1ysHZE2Wz/vault"
			}
		}
		VaultActiveCount: {
			expr: *"count(vault_standby{kubernetes_namespace=\"sys-vault\"} == 0) != 1" | string
			for:  *"10m" | string
			annotations: {
				description: """
					More or less than 1 active instance typically indicates a problem with leader election.

					"""

				summary:   "There are {{ $value }} active Vault instance(s)"
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/1ysHZE2Wz/vault"
			}
		}
		VaultUp: {
			expr: *"vault_up{kubernetes_namespace=\"sys-vault\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: """
					The exporter runs as a sidecar and should be able to connect to port 8200 on localhost.

					"""

				summary:   "Vault exporter for '{{ $labels.kubernetes_pod_name }}' cannot talk to Vault."
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/1ysHZE2Wz/vault"
			}
		}
		VaultServerUnreachable: {
			expr: *"probe_success{job=\"vault-server\"} == 0" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} has been down for more than 5 minutes."
				summary:     "Vault server is not reachable."
			}
		}
		VaultServerBlackboxTargetDown: {
			expr: *"up{job=\"vault-server\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} http probe job reports down more than 5 minutes."
				summary:     "Vault server http probe job down"
			}
		}
		VaultSidecarCredentialsExpired: {
			expr: *"time() - vkcc_sidecar_expiry_timestamp_seconds{kubernetes_namespace=~\"kube-system|sys-.*\"} > 0" | string
			for:  *"10m" | string
			annotations: {
				description: """
					The credentials served by the vault credentials agent sidecar have expired and have not
					been renewed. This may cause issues for the other containers in the pod.

					"""

				summary:   "The credentials for '{{ $labels.kubernetes_pod_name }}' have expired"
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/U61wpstMk/vault-credentials-sidecars"
			}
		}
		VaultSidecarDown: {
			expr: *"up{job=\"vault-credentials-agents\",kubernetes_namespace=~\"kube-system|sys-.*\"} == 0" | string
			for:  *"10m" | string
			annotations: {
				description: """
					The vault credentials agent sidecar is down. This may cause issues for the other containers
					in the pod.

					"""

				summary:   "The vault credentials agent for '{{ $labels.kubernetes_pod_name }}' is down"
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/U61wpstMk/vault-credentials-sidecars"
			}
		}
		VaultSidecarMissing: {
			expr: *"(kube_pod_annotations{annotation_injector_tumblr_com_request=~\"vault-sidecar-.+\"} and on (pod,namespace) kube_pod_status_scheduled{condition=\"true\"} == 1) unless on (pod,namespace) kube_pod_container_info{container=~\"vault-credentials-agent.*\"}" | string
			for:  *"10m" | string
			annotations: {
				description: """
					The pod is annotated with `{{ $labels.key }}={{ $labels.value }}` but does not have a
					container matching the name `vault-credentials-agent.*`. This indicates an issue with
					the sidecar injection. Check the `kube-system/k8s-sidecar-injector` deployment for problems.

					"""

				summary:   "Vault sidecar is missing from {{ $labels.namespace }}/{{ $labels.pod }}"
				dashboard: "https://grafana.\(#env.tier).\(#env.provider).uw.systems/d/U61wpstMk/vault-credentials-sidecars"
			}
		}
	}
}

alertGroup: #data
