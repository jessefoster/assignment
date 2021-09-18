# Infrastructure
## Plan
terraform plan -var-file="credentials/secrets.tfvars"

## Apply
terraform apply -var-file="credentials/secrets.tfvars"

cloud_sql_proxy.exe  -instances=idme-assignment:us-west1:hello-world-db-a829a434=tcp:0.0.0.0:1234 -ip_address_types=PRIVATE
