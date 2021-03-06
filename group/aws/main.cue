package aws

#data: {
	name: "aws"
	team: "infra"
	rules: {
		AWSNoMFAConsoleSignin: {
			expr: *"cisbenchmark_sane_no_mfaconsole_signin_sum >= 1" | string
			for:  *"1m" | string
			labels: send_resolved: "false"
			annotations: {
				description: "A user or users signed into the AWS console without MFA enabled"
				summary:     "AWS console login without MFA detected"
				action:      "Identify the users in question from the Cloudtrail logs, disable their account and notify the user."
				logs:        "https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logEventViewer:group=cloudtrail-multi-region;filter=%257B%2520(%2524.eventName%2520%253D%2520%2522ConsoleLogin%2522)%2520%2526%2526%2520(%2524.additionalEventData.MFAUsed%2521%253D%2520%2522Yes%2522)%2520%2526%2526%2520(%2524.responseElements.ConsoleLogin%2520%253D%2520%2522Success%2522)%2520%2526%2526%2520(%2524.userIdentity.type%2521%253D%2520%2522AssumedRole%2522)%257D;start=PT1H"
			}
		}
		AWSRootUsage: {
			expr: *"cisbenchmark_root_usage_sum >= 1" | string
			for:  *"1m" | string
			labels: send_resolved: "false"
			annotations: {
				description: "Cloudtrail logs show activity for the root user"
				summary:     "AWS root account usage detected"
				action:      "Identify the activity in the Cloudtrail logs. Verify if the activity is legitimate. If not, change the root user password, MFA and any access keys immediately. Contact AWS support in the case of complete lock out."
				logs:        "https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logEventViewer:group=cloudtrail-multi-region;filter=%257B%2520%2524.userIdentity.type%2520%253D%2520%2522Root%2522%2520%2526%2526%2520%2524.userIdentity.invokedBy%2520NOT%2520EXISTS%2520%2526%2526%2520%2524.eventType%2521%253D%2520%2522AwsServiceEvent%2522%2520%257D;start=PT1H"
			}
		}
		CredentialsDisablerJob: {
			expr: *'(time() - max(kube_job_status_completion_time{job_name=~"iam-credentials-disabler.*"}))/60/60 > 72' | string
			annotations: {
				summary:     "AWS CredentialsDisabler Job (running in sys-cis-benchmark namespace) has not run in over 72h"
				action:      "Check that Pod is running / check logs."
			}
		}
	}
}

alertGroup: #data
