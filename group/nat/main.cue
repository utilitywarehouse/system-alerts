package nat

#data: {
	name: "nat"
	team: "infra"
	rules: {
		NATNodeDown: {
			expr:     *"up{job=\"nat-node\"} != 1" | string
			for: *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} reports down more than \(for)."
				summary:     "NAT node exporter job down"
			}
		}
		NATNotHealthy: {
			expr:     *"bgp_lb_path_advertisement{job=\"nat-bgp\", prefix=\"0.0.0.0\", prefix_length=\"0\"} != 1" | string
			for: *"10m" | string
			annotations: {
				description: "Internet access has not been advertised via {{ $labels.next_hop }} from instance {{ $labels.instance }} for more than \(for)."
				summary:     "NAT not advertising internet access"
			}
		}
		NATBGPDaemonDown: {
			expr:     *"up{job=\"nat-bgp\"} != 1" | string
			for: *"10m" | string
			annotations: {
				description: "Cannot get metrics from {{ $labels.instance }} bgp daemon for more than \(for)."
				summary:     "NAT BGP daemon down"
			}
		}
	}
}

alertGroup: #data
