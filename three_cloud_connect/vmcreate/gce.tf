resource "google_compute_instance" "default" {
  for_each     = { for subnet in var.gcp_subnet_map_list : subnet.name => subnet }
  project      = var.googleCloud.project
  name         = "${var.gce_setting_props.name}-${each.key}"
  machine_type = var.gce_setting_props.machine_type
  zone         = var.gce_setting_props.zone

  tags = var.gce_setting_props.tags

  boot_disk {
    initialize_params {
      image = var.gce_setting_props.boot_disk.image
      size  = var.gce_setting_props.boot_disk.size
      type  = var.gce_setting_props.boot_disk.type
    }
    device_name = var.gce_setting_props.boot_disk.device_name
  }

  network_interface {
    subnetwork = "${var.gcp_vpc_name}-${each.value.name}"
  }

  service_account {
    scopes = var.gce_setting_props.service_account_scopes
  }
}
