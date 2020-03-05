// PROVIDER DEFINED HERE "GOOGLE"
provider "google" {
  credentials = "${file("venkat_service_account.json")}"
  project     = "${var.venkat-project}"
  //region      = "us-central1"
  //  zone = "us-central1-a"
}

// BELOW IS NETWORK PART
resource "google_compute_network" "vpc_network" {
  name        = "${var.elk-vpc-network}"
  description = " this is 247 private network"

}

// CREATES FIREWALL IN "bang-network" VPC
resource "google_compute_firewall" "myfirewall" {
  name    = "${var.elk-firewall}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080", "7000", "9042", "5601"]
  }
  //source_tags = ["web"]
}

// CREATE INSTANCE IN ABOVE VPC with firewall ATTACHED
resource "google_compute_instance" "myinstance" {
  //name         = "test-vm-centos7-2"
  count        = "${var.vmcount}"
  name         = "${var.vm-name}-${count.index + 1}"
  machine_type = "${var.machine-type}"
  zone         = "${var.region}"
  tags         = ["foo", "bar"]
  boot_disk {
    initialize_params {
      image = "${var.image_type}"
    }
  }


  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }
  network_interface {
    network = "${google_compute_network.vpc_network.name}"
    access_config {
      // Ephemeral IP
    }
  }
  metadata = {
    bar = "foo"
  }
  //metadata_startup_script = "${file("installelk.sh")}"
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  provisioner "remote-exec" {
    inline = [
      "echo ========================== CREATING /tmp/provisioning ========================",
      "sudo mkdir -p /tmp/provisioning",
      "sudo chown -R venkat:venkat  /tmp/provisioning/"
    ]
    connection {
      type        = "ssh"
      user        = "venkat"
      host        = self.network_interface[0].access_config[0].nat_ip
      agent       = true
      private_key = file("id_rsa")
    }
  }

  provisioner "file" {
    source      = "installelk.sh"
    destination = "/tmp/provisioning/installelk.sh"
    connection {
      type        = "ssh"
      user        = "venkat"
      host        = self.network_interface[0].access_config[0].nat_ip
      agent       = true
      private_key = file("id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ========================== running test.sh ========================",
      "pwd",
      "cd /tmp/provisioning/",
      "sudo sh /tmp/provisioning/installelk.sh"

    ]
    connection {
      type        = "ssh"
      user        = "venkat"
      host        = self.network_interface[0].access_config[0].nat_ip
      agent       = true
      private_key = file("id_rsa")
    }
  }


}
