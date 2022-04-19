package wiresteward

#data: {
	name: "wiresteward"
	team: "infra"
	rules: {
		WirestewardNodeDown: {
			expr:     *"up{job=\"wiresteward-node\"} != 1" | string
			for: *"5m" | string
			annotations: {
				description: "{{ $labels.instance }} reports down more than \(for)."
				summary:     "Wiresteward node exporter job down"
			}
		}
	}
}

alertGroup: #data
