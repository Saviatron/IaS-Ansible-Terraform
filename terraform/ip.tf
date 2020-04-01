resource "google_compute_address" "ip-lb" {
  name = "ip-lb"
}
resource "google_compute_address" "ip-ws1" {
  name = "ip-ws1"
}
resource "google_compute_address" "ip-ws2" {
  name = "ip-ws2"
}
resource "google_compute_address" "ip-int-lb" {
  name         = "ip-int-lb"
  subnetwork   = "default"
  address_type = "INTERNAL"
  address      = "10.128.0.11"
  region       = "us-central1"
}
resource "google_compute_address" "ip-int-ws1" {
  name         = "ip-int-ws1"
  subnetwork   = "default"
  address_type = "INTERNAL"
  address      = "10.128.0.12"
  region       = "us-central1"
}
resource "google_compute_address" "ip-int-ws2" {
  name         = "ip-int-ws2"
  subnetwork   = "default"
  address_type = "INTERNAL"
  address      = "10.128.0.13"
  region       = "us-central1"
}
