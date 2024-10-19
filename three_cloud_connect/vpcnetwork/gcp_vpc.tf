# provider "google" {
#   project     = var.googleCloud.project
#   region      = var.googleCloud.region
#   credentials = file(var.googleCloud.credentials)
# }

resource "google_compute_network" "my_gcp_vpc" {
  name                    = "${var.gcp_vpc_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460
}

# Private subnet
resource "google_compute_subnetwork" "my_gcp_subnets" {
  for_each = { for i in var.gcp_subnet_map_list : i.name => i }

  network       = google_compute_network.my_gcp_vpc.name
  name          = "${var.gcp_vpc_name}-${each.value.name}"
  ip_cidr_range = each.value.cidr
  region        = each.value.region
}

# Firewall rule
resource "google_compute_firewall" "allow_ssh" {
  network   = google_compute_network.my_gcp_vpc.name
  name      = "${var.gcp_vpc_name}-ssh-allow-rule"
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000
}

resource "google_compute_firewall" "allow_internal" {
  for_each = { for i in var.fw_ingress_map_list : i.name => i }

  network   = google_compute_network.my_gcp_vpc.name
  name      = "${var.gcp_vpc_name}-${each.value.name}"
  direction = "INGRESS"
  allow {
    protocol = "all"
  }
  source_ranges = each.value.source_ranges
  priority      = each.value.priority
}

resource "google_compute_firewall" "allow_vpn_external" {
  for_each = { for i in var.fw_egress_map_list : i.name => i }

  network   = google_compute_network.my_gcp_vpc.name
  name      = "${var.gcp_vpc_name}-${each.value.name}"
  direction = "EGRESS"
  allow {
    protocol = "all"
  }
  source_ranges      = each.value.source_ranges
  destination_ranges = each.value.destination_ranges
  priority           = each.value.priority
}
