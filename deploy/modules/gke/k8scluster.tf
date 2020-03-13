

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  #create vpc, subnet, nat
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc_network.name

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "private_pool" {
  cluster            = google_container_cluster.primary.name
  initial_node_count = 1 ##was 10
  location           = google_container_cluster.primary.location
  #   max_pods_per_node  = 32
  name    = "recorder"
  project = var.project
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    max_node_count = 100
    min_node_count = 1
  }
  node_config {
    machine_type = "n1-standard-1" #was 8

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

}




resource "google_compute_network" "vpc_network" {
  name = "vpc-network"

}


resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "tooling-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  secondary_ip_range {
    range_name    = "secondary-range"
    ip_cidr_range = "192.168.10.0/24"
  }
}




resource "google_compute_router_nat" "nat" {
  name                               = "perftool-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_router" "router" {
  name    = "perftool-router"
  region  = google_compute_subnetwork.network-with-private-secondary-ip-ranges.region
  network = google_compute_network.vpc_network.self_link

  bgp {
    asn = 64514
  }
}

module "external-rules" {
  source = "git::ssh://git@gitlab.internal.unity3d.com/cloud-devops/terraform-modules/cloud-armor-external-access.git?ref=1.0.0"

  region  = google_compute_subnetwork.network-with-private-secondary-ip-ranges.region
  project = var.project
  env     = "test"
  name    = "cd"
}



# module "nat" {
#   source = "GoogleCloudPlatform/nat-gateway/google"
#   # region = var.region
#   # zone   = "us-central1-f"
#   # tags       = ["${var.gke_node_tag}"]x
#   # network    = "vpc-network"
#   # subnetwork = "tooling-subnetwork"
#   region     = "us-central1"
#   network    = "default"
#   subnetwork = "default"
# }



# resource "google_compute_route" "gke-master-default-gw" {
#   count            = "${var.gke_master_ip == "" ? 0 : length(split(";", var.gke_master_ip))}"
#   name             = "tooling-gateway"
#   dest_range       = "34.69.146.147"
#   network          = "vpc-network"
#   next_hop_gateway = "default-internet-gateway"
#   # tags             = ["${var.gke_node_tag}"]
#   priority = 700
# }
