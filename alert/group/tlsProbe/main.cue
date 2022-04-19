package tlsProbe

#data: {
	name: "tls-probe"
	team: "infra"
	rules: {
		TLSProbeTargetDown: {
			expr:     *"up{job=~\"^tls-cert-.*$\"} != 1" | string
			for: *"5m" | string
			annotations: {
				description: "{{ $labels.instance }} tls probe job reports down more than \(for)."
				summary:     "Traefik instance tcp probe job down"
			}
		}
		TLSProbeFailed: {
			expr: *"probe_success{job=~\"^tls-cert-.*$\"} == 0" | string
			for:  *"2m" | string
			annotations: {
				description: "{{ $labels.instance }} probe fails, check blackbox exporter probes for details (blackbox pods port :9115)"
				summary:     "Traefik tls probe failed"
			}
		}
		TLSCertExpiringSoon: {
			expr: *"probe_ssl_earliest_cert_expiry{job=~\"^tls-cert-.*$\"} - time() < 86400 * 28" | string
			annotations: {
				description: "{{ $labels.instance }} certificate expires in less than 28 days"
				summary:     "SSL Certificate is due to expire in less than 28 days"
			}
		}
	}
}

alertGroup: #data
