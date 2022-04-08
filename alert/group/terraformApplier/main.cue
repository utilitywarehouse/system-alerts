package terraformApplier

#env: {
	team:      *"infra" | string
	groupName: *"terraform-applier" | string
}

#data: {
	name: #env.groupName
	team: #env.team
	rules: {
		TerraformApplierErrors: {
			expr: *"terraform_applier_module_apply_success{kubernetes_namespace=~\"kube-system|sys-.+\"} == 0" | string
			for:  *"1h10m" | string
			annotations: {
				summary: "terraform-applier in {{ $labels.kubernetes_namespace }} encountered errors while applying {{ $labels.module }}"
				description: """
					Some resources may not have been applied.

					If the state is locked you can remove the lock with the following command:
					`kubectl --context={{ $labels.kubernetes_cluster }} -n {{ $labels.kubernetes_namespace }} patch lease lock-tfstate-default-{{ $labels.module }} --type=json -p='[{\"op\": \"remove\", \"path\": \"/spec/holderIdentity\"}]'`

					"""
			}
		}
	}
}

alertGroup: #data
