package gcp

#data: {
	name: "gcp"
	team: "infra"
	rules: {
		GCPDiskSnapshotterDown: {
			expr: *"sum(up{app=\"gcp-disk-snapshotter\"}) < 1 or absent(up{app=\"gcp-disk-snapshotter\"})" | string
			for:  *"5m" | string
			annotations: {
				description: "{{ $labels.instance }} is down"
				summary:     "GCP Disk Snapshotter is down"
			}
		}
		GCPDiskSnapshotterError: {
			expr: *"rate(gcp_disk_snapshotter_create_api_call_count{success=\"false\"}[5m]) > 0 or rate(gcp_disk_snapshotter_delete_api_call_count{success=\"false\"}[5m]) > 0 or rate(gcp_disk_snapshotter_operation_count{success=\"false\"}[5m]) > 0" | string
			for:  *"15m" | string
			annotations: {
				description: "{{ $labels.instance }} is encountering errors"
				summary:     "GCP Disk Snapshotter is encountering errors"
			}
		}
	}
}

alertGroup: #data
