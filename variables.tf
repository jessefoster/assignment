variable "db_sa_password" {
	type = string
	sensitive = true
}

variable "db_jmf9u_password" {
	type = string
	sensitive = true
}

variable "credentials_file" {
  type = string
}

variable "project_id" {
    type = string
    default = "idme-assignment"
}

variable "region" {
    type = string
    default = "us-west1"
}