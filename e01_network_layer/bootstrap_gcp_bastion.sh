#!/bin/bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p
firewall-cmd --add-masquerade
firewall-cmd --add-masquerade --permanent
