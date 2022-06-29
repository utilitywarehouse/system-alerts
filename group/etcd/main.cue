package etcd

#env: {
	provider:  string
	environment:      string
}

#data: {
	name: "etcd"
	team: "infra"
	rules: {
		KubernetesEtcdNodeDown: {
			expr: *"up{job=\"etcd\"} != 1" | string
			for:  *"10m" | string
			annotations: {
				description: "{{ $labels.instance }} has been down for more than 10 minutes."
				summary:     "Kubernetes etcd node is down"
				impact:      "etcd cluster has limited node redundancy."
				action:      "Check etcd service status on {{$labels.instance}}."
				dashboard:   "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/mYdnw3aik/kubernetes-etcd"
			}
		}
		KubernetesEtcdNoLeader: {
			expr: *"etcd_server_has_leader{job=\"etcd\"} == 0" | string
			for:  *"1m" | string
			annotations: {
				summary: "{{$labels.instance}} has no leader."
				impact:  "etcd cluster {{$labels.instance}} is not available."
				action:  "Check etcd service status on {{$labels.instance}}."
			}
		}
		KubernetesEtcdHighNumberOfFailedGRPCRequests: {
			expr: *"100 * sum(rate(grpc_server_handled_total{grpc_code!=\"OK\",job=\"etcd\"}[5m])) by ( instance, grpc_service,grpc_method) /  sum(rate(grpc_server_handled_total{job=\"etcd\"}[5m])) by (instance, grpc_service, grpc_method) > 1" | string
			for:  *"10m" | string
			annotations: {
				summary:   "{{$labels.instance}} etcd has many requests failed last 10min"
				impact:    "{{$labels.instance}} etcd is returning errors."
				action:    "Check RPC failed rate on dashboard and {{$labels.instance}} etcd service logs."
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/mYdnw3aik/kubernetes-etcd"
			}
		}
		// https://github.com/etcd-io/etcd/issues/11100#issuecomment-613776203
		// > It looks to me like the RAFT_MESSAGE round-tripper is not very
		// > relevant to performance delivered to clients.
		//
		// https://github.com/etcd-io/etcd/issues/10292
		//KubernetesEtcdMemberCommunicationSlow: {
		// expr: *"histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket{job=\"etcd\"}[5m])) > 0.2048" | string
		// for:  *"10m" | string
		// annotations: {
		//  summary:   "{{$labels.instance}} member communication is slow"
		//  impact:    "{{$labels.instance}} is responding slowly."
		//  action:    "Check {{$labels.instance}} etcd service logs."
		//  dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/mYdnw3aik/kubernetes-etcd"
		// }
		//}
		KubernetesEtcdHighNumberOfFailedProposals: {
			expr: *"rate(etcd_server_proposals_failed_total{job=\"etcd\"}[5m]) > 0" | string
			for:  *"15m" | string
			annotations: {
				summary:   "{{$labels.instance}} etcd member has a high number of raft proposals failing."
				impact:    "{{$labels.instance}} etcd might not be working."
				action:    "Check Raft proposals dashboard and {{$labels.instance}} etcd service logs."
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/mYdnw3aik/kubernetes-etcd"
			}
		}
		KubernetesEtcdHighDiskSyncDurations: {
			expr: *"histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket{job=\"etcd\"}[5m])) > 0.5" | string
			for:  *"10m" | string
			annotations: {
				summary:   "{{$labels.instance}} etcd fsync durations are high"
				impact:    "{{$labels.instance}} etcd is responding slowly."
				action:    "Check Disk Sync Duration and resources for {{$labels.instance}}."
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/mYdnw3aik/kubernetes-etcd"
			}
		}
		KubernetesEtcdHighCommitDurations: {
			expr: *"histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket{job=\"etcd\"}[5m])) > 0.25" | string
			for:  *"10m" | string
			annotations: {
				summary:   "{{$labels.instance}} etcd commit durations are high"
				impact:    "{{$labels.instance}} etcd is responding slowly."
				action:    "Check {{$labels.instance}} resources."
				dashboard: "https://grafana.\(#env.environment).\(#env.provider).uw.systems/d/mYdnw3aik/kubernetes-etcd"
			}
		}
		EtcdBackupJobFailed: {
			expr: *"time() - max(kube_job_status_completion_time{namespace=\"kube-system\",job_name=~\"etcd-backup-.*\"}) > 108000" | string
			annotations: {
				summary: "Etcd backup jobs have not completed in the last 30h"
				action:  "Check cronjob status and job logs "
			}
		}
	}
}

alertGroup: #data
