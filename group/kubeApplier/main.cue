package kubeApplier

#data: {
	name: "kube-applier"
	team: "infra"
	rules: {
		KubeApplierGitSyncError: {
			expr: *"time() - kube_applier_git_last_sync_timestamp{kubernetes_namespace=\"sys-kube-applier\"} > 3600" | string
			for:  *"10m" | string
			annotations: {
				summary: "kube-applier has not been able to sync the git repository in the last hour"
				impact:  "Recent changes have not been applied."
			}
		}
		KubeApplierErrors: {
			expr: *"kube_applier_last_run_success * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"system\"} != 1" | string
			for:  *"1h10m" | string
			annotations: {
				summary: "kube-applier encountered errors while applying {{ $labels.namespace }}"
				impact:  "Some manifest won't be automatically deployed."
			}
		}
		KubeApplierKubectlKilled: {
			expr: *"sum(rate(kube_applier_kubectl_exit_code_count{exit_code=\"-1\"}[5m])) * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"system\"} > 0" | string
			for:  *"10m" | string
			annotations: {
				description: "kubectl is returning an exit code of -1 which indicates it was killed, probably by the OOM killer"
				summary:     "kube-applier: kubectl is being killed in {{ $labels.namespace }}"
				impact:      "namespaces may fail to apply"
			}
		}
		KubeApplierAutoApplyIsDisabled: {
			expr: *"kube_applier_waybill_spec_auto_apply * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"system\"} == 0" | string
			for:  *"1h" | string
			annotations: {
				description: "to check status: `kubectl -n {{ $labels.namespace }} describe waybill`"
				summary:     "kube-applier disabled in {{ $labels.namespace }} for 1 hr"
			}
		}
		KubeApplierRunningInDryRun: {
			// Trigger only if both auto_apply and dry_run are set to true
			expr: *"(kube_applier_waybill_spec_auto_apply + kube_applier_waybill_spec_dry_run) * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"system\"} == 2" | string
			for:  *"1h" | string
			annotations: {
				description: "to check status: `kubectl -n {{ $labels.namespace }} describe waybill`"
				summary:     "kube-applier running in dry run mode in {{ $labels.namespace }} for 1 hr"
			}
		}
		KubeApplierRunIsLate: {
			expr: *"kube_applier_waybill_spec_auto_apply * time() - kube_applier_last_run_timestamp_seconds - 2*kube_applier_waybill_spec_run_interval * on(namespace) group_left kube_namespace_labels{label_uw_systems_owner=\"system\"} > 0" | string
			for:  *"15m" | string
			annotations: {
				description: """
					The last full run of kube-applier finished over an hour ago. A new
					run should finish roughly every hour, so this may indicate that kube-applier
					is hung, hasn't initiated a new run or is taking much longer than expected to finish.

					"""

				summary: "kube-applier: last run in {{ $labels.namespace }} is too old"
				impact:  "Some of the latest changes may not have been applied"
			}
		}
	}
}

alertGroup: #data
