terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.84.0"
    }
  }
}

provider "google-beta" {
  credentials = file(var.credentials_file)
  # ID, not the name
  project = var.project_id
  region  = var.region
}

provider "google" {
  credentials = file(var.credentials_file)
  # ID, not the name
  project = var.project_id
  region  = var.region
}

# VPC
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "3.4.0"

  project_id              = var.project_id
  network_name            = "infinite-hellos"
  auto_create_subnetworks = true
  subnets = [
    {
      subnet_name   = "serverless-subnet"
      subnet_ip     = "10.10.0.0/28"
      subnet_region = var.region
    }
  ]
}

# Allow Cloud Run to connect to Database with private ip via VPC Serveless Connector
resource "google_project_service" "vpcaccess-api" {
  project = var.project_id
  service = "vpcaccess.googleapis.com"

}

resource "google_vpc_access_connector" "us-west-vpc-serverless-connector" {
	provider		= google-beta
	name    		= "us-west-serverless"
	project			= var.project_id
	region			= var.region
	subnet {
		name = module.vpc.subnets["us-west1/serverless-subnet"].name
	}
	machine_type  = "e2-standard-4"
    min_instances = 2 # lowest value is 2
    max_instances = 3

	depends_on = [
		google_project_service.vpcaccess-api
	]
}

# IP address pool for Private Services -> Database
resource "google_compute_global_address" "googleservices-connect-ips" {
  name          = "googleservices-connect-ips"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 24
  network       = module.vpc.network_id
}

resource "google_service_networking_connection" "googleservices-vpc" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.googleservices-connect-ips.name]
}

# Database
resource "random_id" "db_name_suffix" {
  byte_length = 4
}
resource "google_sql_database_instance" "hello_world_storage" {

  // Names can't be reused for up to week, add random bits to the end to bypass issue
  name             = "hello-world-db-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_13"

  depends_on = [google_service_networking_connection.googleservices-vpc]

  settings {
    // Postgres only supports shared core or dedicated instance types
    tier = "db-g1-small"
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.vpc.network_id
    }
  }
}

# Create default database within Postgres instance
resource "google_sql_database" "database" {
  name     = "helloworld"
  instance = google_sql_database_instance.hello_world_storage.name
}

resource "google_sql_user" "hello_db_sa" {
  name     = "hello_world_sa"
  password = var.db_sa_password
  instance = google_sql_database_instance.hello_world_storage.name
}

resource "google_sql_user" "hello_db_jmf9u" {
  name     = "jmf9u"
  password = var.db_jmf9u_password
  instance = google_sql_database_instance.hello_world_storage.name
}

# Server
resource "google_cloud_run_service" "hello_world_service" {
  name     = "assignment-app"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/idme-assignment/assignment-jvm-458ff08d-6ce5-488f-97dd-671acd626f9f"
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.hello_world_storage.connection_name
		"run.googleapis.com/vpc-access-connector": google_vpc_access_connector.us-west-vpc-serverless-connector.name
      }
    }
  }
  autogenerate_revision_name = true

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Make service publically available
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.hello_world_service.name
  location = google_cloud_run_service.hello_world_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_service.hello_world_service.status[0].url
}

############
# React page via CDN
# https://medium.com/swlh/setup-a-static-website-cdn-with-terraform-on-gcp-23c6937382c6
# https://github.com/gruntwork-io/terraform-google-static-assets/tree/master/modules/cloud-storage-static-website
###########
# resource "google_storage_bucket" "hello-react-ui" {
#   provider = google
#   name     = "hello-react-ui"
#   location = "US"
# }

# # Anyone can access
# resource "google_storage_default_object_access_control" "hello-ui-read" {
#   bucket = google_storage_bucket.hello-react-ui.name
#   role   = "READER"
#   entity = "allUsers"
# }

# # Get IP, create DNS record, and map IP to DNS
# resource "google_compute_global_address" "hello-react-ui" {
#   provider = google
#   name     = "website-lb-ip"
# }

# data "google_dns_managed_zone" "gcp_hello_dev" {
#   provider = google
#   name     = "gcp-hello-dev"
# }

# resource "google_dns_record_set" "website" {
#   provider     = google
#   name         = "website.${data.google_dns_managed_zone.gcp_hello_dev.dns_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = data.google_dns_managed_zone.gcp_hello_dev.name
#   rrdatas      = [google_compute_global_address.hello-react-ui.address]
# }