job "storage" {
  region = "us"
  datacenters = ["us-west-2"]

  type = "service"

  update {
    max_parallel = 1
  }

  group "object" {
    count = 2

    restart {
      attempts = 3
      delay    = "30s"
      interval = "2m"
      mode = "delay"
    }

    constraint {
      attribute = "${node.class}"
      value     = "data"
    }

    task "minio" {
      driver = "docker"

      config {
        image = "minio/minio:RELEASE.2017-08-05T00-00-53Z"
        args = [
          "server",
          "http://minio-gcp-0.storage-object-minio.service.europe-west1.consul/data",
          "http://minio-gcp-1.storage-object-minio.service.europe-west1.consul/data",
          "http://minio-aws-0.storage-object-minio.service.us-west-2.consul/data",
          "http://minio-aws-1.storage-object-minio.service.us-west-2.consul/data"
        ]
        network_mode = "host"
        port_map = {
          minio = 9000
        }
      }

      template {
        data = <<EOH
        MINIO_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
        MINIO_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        EOH

        destination = "secrets/file.env"
        env         = true
      }


      service {
        port = "minio"

        tags = [
          "minio",
          "minio-aws-${NOMAD_ALLOC_INDEX}"
        ]
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 10
          port "minio" {
            static = 9000
          }
        }
      }
    }
  }
}
