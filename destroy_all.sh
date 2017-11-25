#!/bin/bash

export TF_VAR_gcp_instance_type='n1-standard-1'
export TF_VAR_aws_instance_type='t2-small'

cd e05_app_layer/
terraform destroy -force
cd ../e04_data_layer/
terraform destroy -force
cd ../e03_scheduler_layer/
terraform destroy -force
cd ../e02_services_lb_layer/
terraform destroy -force
cd ../e01_network_layer/
terraform destroy -force
