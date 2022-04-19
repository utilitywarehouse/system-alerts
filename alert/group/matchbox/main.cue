package matchbox

#data: {
	name: "matchbox"
	team: "infra"
	rules: {
		MatchboxNodeDown: {
			expr: *"up{job=\"matchbox-node\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} reports down more than |(for)."
				summary:     "Matchbox node exporter job down"
			}
		}
		MatchboxHTTPDown: {
			expr:     *"probe_success{job=\"matchbox-http\"} != 1" | string
			for: *"10m" | string
			annotations: {
				description: "Matchbox http endpoint has been down on {{ $labels.instance }} for more than \(for)."
				summary:     "Matchbox http endpoint is down"
			}
		}
	}
}

alertGroup: #data
