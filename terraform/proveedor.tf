provider "google" {
  credentials = file("~/credentials.json")
  project     = "stellar-psyche-268616"
  region      = "us-central1"
  zone        = "us-central1-a"
}
