package logging

#env: {
	provider:  string
	environment:      string
}

#data: {
	name: "logging"
	team: "infra"
	rules: {
		"LogForwarderIsDown(external)": {
			expr: *"up{job=\"log-forwarder\"} < 1" | string
			for:  *"30m" | string
			annotations: {
				summary: "{{ $labels.instance }} log forwarder is not exposing metrics for 30m"
				action:  "ssh into {{ $labels.instance }} and make sure `log-forwarder.service` is running"
			}
		}
		"LogForwarderFailingToInput(kube)": {
			expr: *"rate(fluentd_input_status_num_records_total{job=\"kubernetes-pods\",kubernetes_pod_name=~\"forwarder-.*\"}[5m]) == 0" | string
			for:  *"2h" | string
			annotations: {
				summary:   "{{ $labels.kubernetes_pod_name }} can't ingest logs from {{ $labels.input }} for 2h"
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/bk2muXYMz/log-forwarder?var-forwarder_pod={{ $labels.kubernetes_pod_name }}"
			}
		}
		"LogForwarderFailingToInput(external)": {
			expr: *"rate(fluentd_input_status_num_records_total{job=\"log-forwarder\"}[5m]) == 0" | string
			for:  *"2h" | string
			annotations: {
				summary:   "{{ $labels.instance }} can't ingest logs from {{ $labels.input }} for 2h"
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/bk2muXYMz/log-forwarder?var-instance={{ $labels.instance }}"
			}
		}
		"LogForwarderFailingToOutput(kube)": {
			expr: *"rate(fluentd_output_status_retry_count{job=\"kubernetes-pods\",kubernetes_pod_name=~\"forwarder-.*\"}[5m]) > 0" | string
			for:  *"15m" | string
			annotations: {
				summary:   "{{ $labels.kubernetes_pod_name }} can't forward logs for 15m"
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/bk2muXYMz/log-forwarder?var-forwarder_pod={{ $labels.kubernetes_pod_name }}"
			}
		}
		"LogForwarderFailingToOutput(external)": {
			expr: *"rate(fluentd_output_status_retry_count{job=\"log-forwarder\"}[5m]) > 0" | string
			for:  *"15m" | string
			annotations: {
				summary:   "{{ $labels.instance }} can't forward logs for 15m"
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/bk2muXYMz/log-forwarder?var-instance={{ $labels.instance }}"
			}
		}
		"LogForwarderBufferFillingUp(kube)": {
			expr: *"fluentd_output_status_buffer_available_space_ratio{job=\"kubernetes-pods\",kubernetes_pod_name=~\"forwarder-.*\"} < 95" | string
			for:  *"15m" | string
			annotations: {
				summary:   "Forwarder buffer is over 5%"
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/bk2muXYMz/log-forwarder?var-forwarder_pod={{ $labels.kubernetes_pod_name }}"
			}
		}
		"LogForwarderBufferFillingUp(external)": {
			expr: *"fluentd_output_status_buffer_available_space_ratio{job=\"log-forwarder\"} < 95" | string
			for:  *"15m" | string
			annotations: {
				summary:   "Forwarder buffer is over 5%"
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/bk2muXYMz/log-forwarder?var-instance={{ $labels.instance }}"
			}
		}
	}
}

alertGroup: #data
