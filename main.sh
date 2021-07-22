#!/usr/bin/env bash

set -euo pipefail

_log() {
    local IFS=$' \n\t'
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2;
}
cluster_info() {
    gcloud container --project "$host_project" clusters list --format json \
        | jq -r --arg 'key' "$1" '.[][$key]'
}
# create_deployment() {
#     local params
#     params="$(jq -nc \
#         --arg ref "$GITHUB_SHA" \
#         --arg environment "$environment" \
#         '{
#             "ref": $ref,
#             "environment": $environment,
#             "auto_merge": false,
#             "required_contexts": [],
#             "production_environment": $environment | startswith("prod")
#         }')"

#     gh api -X POST "/repos/:owner/:repo/deployments" \
#         -H 'Accept: application/vnd.github.ant-man-preview+json' \
#         --input - <<< "$params"
# }

# set_deployment_status() {
#     if [[ -n "${deployment_id:-}" ]]; then
#         local state="$1" \
#             environment_url="${2:-}"
#         gh api --silent -X POST "/repos/:owner/:repo/deployments/$deployment_id/statuses" \
#             -H 'Accept: application/vnd.github.ant-man-preview+json' \
#             -H 'Accept: application/vnd.github.flash-preview+json' \
#             -F "state=$state" \
#             -F "log_url=https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA/checks" \
#             -F "environment_url=$environment_url" \
#             -F 'auto_inactive=true'
#     fi
# }

export IFS=$'\n\t'

# Set helm url based on default, or use provided HELM_URL variable
helm_url="${HELM_URL:-https://helm.clevyr.cloud}"
host_project="${HOST_PROJECT:-momma-motus}"
# Set the project id based on the key file provided, or use the provided project id
project_id="${GCLOUD_GKE_PROJECT:-$(jq -r .project_id <<< "$GCLOUD_KEY_FILE")}"
region="us-central1"

# Put auth stuff here (gcloud, kube-config)
_log Verify tempbuilds folder exists
if [ ! -d deployment/tempbuilds ]; then
    _log tempbuilds folder not found! Exiting!
    exit 1
fi

_log Activate gcloud auth
gcloud auth activate-service-account --key-file - <<< "$GCLOUD_KEY_FILE"
cluster_name="${GCLOUD_CLUSTER_NAME:-$(cluster_info name)}"
docker_repo="${REPO_URL:-us.gcr.io/$project_id}"
echo "$GCLOUD_KEY_FILE" > /tmp/serviceAccount.json
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/serviceAccount.json

_log Select Kubernetes cluster
gcloud container clusters get-credentials  \
    "$cluster_name" \
    --region "$region" \
    --project "$host_project"

_log Starting Terragrunt install...
brew install terragrunt --ignore-dependencies 2>&1 &
tg_install_pid="$!"

_log Add custom helm repo
helm repo add clevyr "$helm_url"
helm repo update

# Generate friendly URL
_log Generating names
mapfile -t adjective < adjectives
mapfile -t name < names
friendlyName=${adjective[RANDOM%${#adjective[@]}]-1}-${name[RANDOM%${#name[@]}]-1}

_log Renaming folder and replacing URL values
cd deployment
prNum=12
folderName="pr"$prNum
mv tempbuilds $folderName
cd $folderName
sed -i "s/REPLACE/$friendlyName/g" helm.yaml

_log Wait for Terragrunt to finish installing...
wait "$tg_install_pid"

_log Initializing Terragrunt
cd ../setup
terragrunt init
cd ../$folderName
terragrunt init
_log Running Terragrunt apply
#terragrunt apply -var=app_image_tag="$folderName"
terragrunt apply -var=app_image_tag="dev" -auto-approve
_log Deployment complete