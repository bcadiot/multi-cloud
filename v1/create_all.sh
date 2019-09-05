#!/bin/bash

export TF_VAR_gcp_instance_type='n1-standard-1'
export TF_VAR_aws_instance_type='t2.small'

cd e01_network_layer/
terraform apply
cd ../e02_services_lb_layer/
terraform apply
cd ../e03_scheduler_layer/
terraform apply
cd ../e04_data_layer/
terraform apply
cd ../e05_app_layer/
terraform apply
cd ../kraken/
terraform apply
