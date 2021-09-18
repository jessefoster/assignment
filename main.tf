terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.84.0"
    }
  }
}

provider "google" {
 credentials = file(var.credentials_file)
 # ID, not the name
 project     = var.project_id
 region      = "us-west1"
}

# VPC
module "vpc" {
	source  = "terraform-google-modules/network/google"
    version = "3.4.0"

	project_id = var.project_id
	network_name = "infinite-hellos"
	auto_create_subnetworks = true
	subnets = [
		{
			subnet_name = "serverless-subnet"
			subnet_ip = "10.10.0.0/28"
			subnet_region = "us-west1"
		}
	]
}

# Allow Cloud Run to connect to Database with private ip
resource "google_project_service" "vpcaccess-api" {
	project = var.project_id
	service = "vpcaccess.googleapis.com"
  
}

module "serverless-connector" {
	source = "terraform-google-modules/network/google//modules/vpc-serverless-connector-beta"
	project_id = var.project_id
	vpc_connectors = [{
		name = "us-west-serverless"
		region = "us-west1"
		subnet_name = module.vpc.subnets["us-west1/serverless-subnet"].name
		machine_type = "e2-standard-4"
		min_instances = 2 # lowest value is 2
		max_instances = 3
	}]

	depends_on = [
	  google_project_service.vpcaccess-api
	]
}

# IP address pool for Private Services -> Database
resource "google_compute_global_address" "googleservices-connect-ips" {
	name = "googleservices-connect-ips"
	purpose = "VPC_PEERING"
	address_type = "INTERNAL"
	ip_version = "IPV4"
	prefix_length = 24
	network = module.vpc.network_id
}

resource "google_service_networking_connection" "googleservices-vpc" {
	network = module.vpc.network_id
	service = "servicenetworking.googleapis.com"
	reserved_peering_ranges = [google_compute_global_address.googleservices-connect-ips.name]
}

# Database
resource "random_id" "db_name_suffix" {
  byte_length = 4
}
resource "google_sql_database_instance" "hello_world_storage" {

    // Names can't be reused for up to week, add random bits to the end to bypass issue
    name =  "hello-world-db-${random_id.db_name_suffix.hex}"
    database_version = "POSTGRES_13"

	depends_on = [ google_service_networking_connection.googleservices-vpc ]

    settings {
      // Postgres only supports shared core or dedicated instance types
      tier = "db-g1-small"
	  ip_configuration {
		ipv4_enabled = false
		private_network = module.vpc.network_id
	  }
    }

}


resource "google_sql_user" "hello_db_sa" {
    name = "hello_world_sa"
    password = var.db_sa_password
    instance = "${google_sql_database_instance.hello_world_storage.name}"
}

resource "google_sql_user" "hello_db_jmf9u" {
    name = "jmf9u"
    password = var.db_jmf9u_password
    instance = "${google_sql_database_instance.hello_world_storage.name}"
}
