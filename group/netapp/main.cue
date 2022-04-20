package netapp

#data: {
	name: "netapp"
	team: "infra"
	rules: {
		NetappExporterDown: {
			expr:     *"up{job=\"netapp-exporter\"} != 1" | string
			for: *"10m" | string
			annotations: {
				description: "{{ $labels.job }} reports down more than \(for)."
				summary:     "Netapp exporter job down"
			}
		}
		NetappVserverAdminState: {
			expr: *"netapp_vserver_state!=1" | string
			for:  *"5m" | string
			annotations: summary: "Opertional state of vserver {{$labels.vserver}} on netapp {{$labels.cluster}} is not in running mode"
		}
		NetappAggrUsage: {
			expr: *"round(netapp_aggr_percent_used_capacity) >= 90" | string
			for:  *"10m" | string
			annotations: summary: "Aggregate {{$labels.aggr}} on netapp {{$labels.cluster}} is more than 90% utilised"
		}
		NetappVolumeState: {
			expr: *"netapp_volume_state!=1" | string
			for:  *"10m" | string
			annotations: summary: "Volume {{$labels.volume}} on netapp {{$labels.cluster}} is not online"
		}
		NetappDiskFailedState: {
			expr: *"netapp_storage_disk_is_failed!=0" | string
			for:  *"10m" | string
			annotations: summary: "Disk {{$labels.disk}} (model: {{$labels.model}}) on netapp {{$labels.cluster}} has failed"
		}
	}
}

alertGroup: #data
