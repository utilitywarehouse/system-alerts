package externalDNS

#data: {
	name: "external-dns"
	team: "infra"
	rules: {
		ExternalDnsRegistryErrors: {
			expr: *"rate(registry_errors_total{app=\"external-dns\"}[5m]) > 0" | string
			for:  *"15m" | string
			annotations: {
				description: "{{ $labels.kubernetes_pod_name }} errors while talking to dns registry"
				summary:     "external-dns registry errors"
			}
		}
		ExternalDnsSourceErrors: {
			expr: *"rate(source_errors_total{app=\"external-dns\"}[5m]) > 0" | string
			for:  *"15m" | string
			annotations: {
				description: "{{ $labels.kubernetes_pod_name }} errors while talking to kube api"
				summary:     "external-dns source errors"
			}
		}
	}
}

alertGroup: #data
