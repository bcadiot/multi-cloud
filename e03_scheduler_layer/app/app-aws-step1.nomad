job "demoapp" {
  region = "us"
  datacenters = ["us-west-2"]

  type = "service"

  update {
    canary       = 1
    max_parallel = 1
  }

  group "webs" {
    count = 2

    restart {
      attempts = 3
      delay    = "30s"
      interval = "2m"
      mode = "delay"
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "httpd"
        port_map = {
          http = 80
        }
      }

      service {
        port = "http"
        tags = [
          "traefik.frontend.rule=Host:demo.exemple.com",
          "traefik.tags=exposed"
          ]
      }

      resources {
        cpu    = 200
        memory = 64

        network {
          mbits = 10
          port "http" {
          }
        }
      }
    }
  }
}
