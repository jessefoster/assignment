# Repos Layout
- App
    - `assignment` - Quarkus based service.  Has ability to compile to native code but ran in JVM mode.
    - `assignment-ui` - React frontend
    - `dbdata` - Directory to store Postgres data for locally running instance
    - `local-stack.yaml` - Local development stack using Postgres
- `credentials` - Directory to store credentials for Terraform and GCP
- `jmeter` - Jmeter tests to put load on application
- 

# Builds
`cloudbuild.yaml` has the Cloud Build configuration.  React frontend is compiled and then copied over to the resource directory in Quarkus.  Quarkus application is then built and packed into Docker container running in JVM mode.

# Infrastructure
`main.tf` Creates all the infrastructure minus the build pipeline.  File includes creation/configuration for
- VPC
- VPC subnets
- VPC connector from Cloud Run to Cloud SQL
- Cloud Run app (publically available, https://assignment-app-t2g7swpm7q-uw.a.run.app)
- Cloud SQL database (private ip)
- User accounts for database

# Monitoring
- Request counts for 2xx and 5xx responses.
- 50%, 95%, and 99% for
  - Request latency for Quakrus
  - Quarkus cpu utilization
  - Quarkus memory utilization
- Request breakdown in Quarkus.  How much in Resource controller vs. waiting on database.
- Postgres open connection count, cpu utilization, memory utilization, transaction count, read ops, and write ops.
- Postgres cpu, memory

This data allows you determine where the overall system is most vulnerable/stressed during periods of high load as well where to scale next.
Examples
- Using all the default settings I noticed Quarkus running in JVM mode uses 1/2 of 512Mb limit, but doesn't increase beyond 3/4 during normal operations.
- The single Postgres instance caps at 47 connections, 3 reserved for GCP, and becomes the blocker to overall performance of the system even though cpu, memory, and I/O is still available.  This shows applications aren't using connection pools effectively to maxmize bandwidth as the instance count rises.

# Other changes/additions if this was real
- Send OpenTelemtry data from Quarkus to New Relic
- Use Secret Manager to provide secrets to Quarkus
- Compile Quarkus in native to lower startup time, cpu utilization, and memory utilizaton.
- Serve static file from storage bucket and CDN instead of 
- Fully automate deployment of container and UI assets.
- Evaluate application usage.  Read heavy? Write Heavy? Certain requests dominate server utilization showing potential for optimizations or API specialization.
- I hooked up New Relic to monitor GCP, add alerts and more dashboard per application instead of cloud resource.
- Store Terraform state in GCP bucket, Git, or use Terraform Enterprise.
- Auto version application with semantic versioning depending on branch.  Master branch -> Major, Patch/Minor Release -> Minor, Dev branch -> increment.
- Separate repositories for configuration/infra code and application code.
- Blue/Green deployment of Quarkus to Cloud Run