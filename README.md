# terragrunt-temp-deploy-action

## Environment Variables

| Variable            | Details                                                                                 | Example                                       |
|---------------------|-----------------------------------------------------------------------------------------|-----------------------------------------------|
| AWS_ACCESS_KEY_ID   | AWS access key ID for Terragrunt to read/write S3 remote state  |
| AWS_SECRET_ACCESS_KEY | Secret for the AWS access key |
| AWS_DEFAULT_REGION  | Default AWS region to use | "us-east-2"
| GCLOUD_KEY_FILE     | The JSON of the key-file to authenticate to Google Cloud.                               | `{"type":"service_account","project_id":...}` |
| GITHUB_TOKEN  |  GitHub token to pull commits
| PASSED_SHA    | SHA for referenced pull request | `${{ github.event.pull_request.head.sha \|\| github.sha }}`
| PR_NUMBER     | PR number from the pull request event | `${{github.event.pull_request.number}}`
| USE_CLEVYR_NAMES    | Set to "true" to generate environment names based on Clevyr employee names, defaults to false, which will generate color-animal based names. 
