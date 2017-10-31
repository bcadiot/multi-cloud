job "app" {
  region = "europe"
  datacenters = ["europe-west1"]

  type = "service"

  update {
    max_parallel = 1
  }

  group "front" {
    count = 3

    restart {
      attempts = 3
      delay    = "30s"
      interval = "2m"
      mode = "delay"
    }

    constraint {
      attribute = "${node.class}"
      value     = "app"
    }

    task "player" {
      driver = "docker"

      config {
        image = "bcadiot/minio-js-store-app:1.1"
        port_map = {
          app = 3000
        }
      }

      env {
        MINIO_EXTERNAL_HOST = "minio-test.example.com"
        MINIO_EXTERNAL_PORT = 80
        MINIO_HOST = "storage-object-minio.service.consul"
        MINIO_PORT = 9000
        MINIO_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
        MINIO_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      }

      service {
        port = "app"
        tags = [
          "traefik.frontend.rule=Host:app-test.example.com",
          "traefik.tags=exposed"
        ]
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 10
          port "app" {
          }
        }
      }
    }
  }
}
