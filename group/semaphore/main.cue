package semaphore

#data: {
	name: "semaphore"
	team: "infra"
	rules: {
		SemaphorePolicyCalicoClientErrors: {
			expr: *"increase(semaphore_policy_calico_client_request_total{success=\"0\"}[5m]) > 0" | string
			for:  *"5m" | string
			annotations: {
				summary:     "{{ $labels.kubernetes_pod_name }} calico client encountered errors on requests for more than 5 minutes"
				description: "GlobalNetworkSets and cross cluster policies may be out of sync due to calico client request failures."
			}
		}
		// According to https://www.wireguard.com/protocol/ handshakes may occur based on `REKEY_AFTER_TIME` and `REJECT_AFTER_TIME` values.
		// Checking on the defaults: https://github.com/WireGuard/wireguard-monolithic-historical/blob/master/src/messages.h seems like
		// the worst case scenario is 5mins between 2 handshakes. Lets allow double that and alert if we see that handshaking between peers
		// takes more than 10 minutes. Also, allowing a 5 minute time window before firing to cover for the satrup delay, where the first peer
		// handshake hasn't happened yet and semaphore_wg_peer_last_handshake_seconds is 0.
		SemaphoreWGPeerLastHandshakeTooFar: {
			expr: *"time() - semaphore_wg_peer_last_handshake_seconds > 600" | string
			for:  *"5m" | string
			annotations: {
				summary:     "wg latest handshake with peer on {{ $labels.device }} device happened more than 10 minutes ago"
				description: "Instance: {{ $labels.instance }} wg latest handshake with peer {{ $labels.public_key }} on {{ $labels.device }} device happened more than 10 minutes ago."
			}
		}
		SemaphoreWireguardFailedToSyncPeers: {
			expr: *"increase(semaphore_wg_sync_peers_total{success=\"0\"}[5m]) > 0" | string
			for:  *"5m" | string
			annotations: {
				summary:     "{{ $labels.instance }} wg client encountered errors on set peers requests for more than 5 minutes"
				description: "WG peers list might be out of sync due to wg client failures."
			}
		}
		SemaphoreWireguardNodeWatcherErrors: {
			expr: *"rate(semaphore_wg_node_watcher_failures_total[5m]) > 0" | string
			for:  *"10m" | string
			annotations: {
				summary:     "{{ $labels.kubernetes_pod_name }} node watcher to {{ $labels.cluster }} is encountered errors on {{ $labels.verb }} actions for more than 10 minutes"
				description: "Semaphore Wireguard controller fails to {{ $labels.verb }} on cluster {{ $labels.cluster }} node resource."
			}
		}
		SemaphoreServiceMirrorMismatch: {
			expr: *"semaphore_service_mirror_kube_watcher_objects{watcher=~\".*-mirror.*\"} - ignoring(watcher) semaphore_service_mirror_kube_watcher_objects{watcher!~\".*-mirror.*\"} != 0" | string
			for:  *"10m" | string
			annotations: {
				summary:     "{{ $labels.app }}: the number of mirrored {{ $labels.kind }} objects is different to the remote count"
				description: "The number of local mirrored objects should match the number of remote objects."
			}
		}
		SemaphoreServiceMirrorRequeued: {
			expr: *"semaphore_service_mirror_queue_requeued_items > 0" | string
			for:  *"10m" | string
			annotations: {
				summary: "{{ $labels.app }} has been requeuing {{ $labels.name }} objects for 10 minutes"
				description: """
					Items are requeued when an error is encountered during reconcilliation.

					If requeued items are not being processed promptly then this indicates a persistent issue. The mirror services are likely to be in an incorrect state.

					"""
			}
		}
		SemaphoreServiceMirrorKubeClientErrors: {
			expr: *"increase(semaphore_service_mirror_kube_http_request_total{code!=\"200\"}[5m]) > 0" | string
			for:  *"10m" | string
			annotations: {
				summary:     "{{ $labels.app }} kubernetes client reports errors speaking to apiserver at {{ $labels.host }} for more than 10 minutes"
				description: "Kubernetes client requests returning code different than 200 for longer than 10 minutes. Check the pods logs for further information."
			}
		}
	}
}

alertGroup: #data
