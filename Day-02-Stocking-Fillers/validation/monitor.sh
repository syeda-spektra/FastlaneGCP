#!/bin/bash
# Day 2 - Stocking Fillers | support diagnostics. Run in the learner's Cloud Shell.
P=$(gcloud config get-value project 2>/dev/null)
R=us-central1
B=$(gcloud storage buckets list --format='value(name)' --filter='name~^hollyfield-workbench-')
echo "==== [1/6] Project: $P | Region: $R | Workbench: $B ===="
echo "==== [2/6] Services ===="
gcloud services list --enabled --format="value(config.name)" | grep -E "^(run|cloudbuild|artifactregistry|aiplatform|logging)\.googleapis" | sort
echo "==== [3/6] Core-banking API ===="
gcloud run services describe hollyfield-core-banking --region $R --format="value(status.url,status.conditions[0].status)" 2>&1
gcloud builds list --region $R --filter="tags=hollyfield-core-banking" --limit 3 --format="table(id,status,createTime)" 2>&1
echo "==== [4/6] Builder permissions ===="
gcloud projects get-iam-policy $P --flatten="bindings[].members" --filter="bindings.members:hollyfield-builder" --format="value(bindings.role)"
echo "==== [5/6] Holly's trace (last 2h) ===="
gcloud logging read 'logName:holly-trace' --freshness 2h --limit 30 --format="table(timestamp,jsonPayload.message,jsonPayload.tool,jsonPayload.status,jsonPayload.error_code)"
echo "==== [6/6] Holly's uploaded code ===="
gcloud storage ls gs://$B/app/holly/ 2>&1
