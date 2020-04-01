resource "google_compute_instance" "lb" {
  name         = "terraform-lb"
  machine_type = "n1-standard-1"
  tags         = ["terraform", "http-server"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1910-eoan-v20200331"
    }
  }
  network_interface {
    network    = "default"
    network_ip = google_compute_address.ip-int-lb.address
    access_config {
      nat_ip = google_compute_address.ip-lb.address
    }
  }
  metadata = {
    ssh-keys = "javimm97:${file("~/.ssh/sshkey.pub")}"
  }
}

resource "google_compute_instance" "ws1" {
  name         = "terraform-ws1"
  machine_type = "n1-standard-1"
  tags         = ["terraform", "http-server"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1910-eoan-v20200331"
    }
  }
  network_interface {
    network    = "default"
    network_ip = google_compute_address.ip-int-ws1.address
    access_config {
      nat_ip = google_compute_address.ip-ws1.address
    }
  }
  metadata = {
    ssh-keys = "javimm97:${file("~/.ssh/sshkey.pub")}"
  }
}

resource "google_compute_instance" "ws2" {
  name         = "terraform-ws2"
  machine_type = "n1-standard-1"
  tags         = ["terraform", "http-server"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1910-eoan-v20200331"
    }
  }
  network_interface {
    network    = "default"
    network_ip = google_compute_address.ip-int-ws2.address
    access_config {
      nat_ip = google_compute_address.ip-ws2.address
    }
  }
  metadata = {
    ssh-keys = "javimm97:${file("~/.ssh/sshkey.pub")}"
  }
}
