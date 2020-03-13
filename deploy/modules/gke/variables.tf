variable "project" {
  //unity-cs-recorderjmeter-test"
  type        = string
  description = "performance tooling cloud project"



}

variable "region" {
  type        = string
  description = "region of deployments"

}

variable "cluster_name" {

  type        = string
  description = "name of the k8s cluster"

}
