#!/bin/bash

# Check arch
if [ "$(uname -m)" != "x86_64" ]; then
	cat <<EOF
ERROR: Unsupported architecture: $(uname -m)
Only x86_64 architectures are supported at this time
EOF
	exit 1
fi

# Check dist

lsb_dist="$(. /etc/os-release && echo "$ID")"
lsb_version="$(. /etc/os-release && echo "$VERSION_ID")"
case "$${lsb_dist}" in
	fedora|centos|rhel)
		echo "OK : $${lsb_dist} detected"
		yum clean all
		yum install -y redhat-lsb-core
		;;
	*)
		echo "ERROR: Cannot detect Linux distribution or it's unsupported"
		exit 1
		;;
esac

# Extended Params
ZONE=${zone}
REGION=${region}
CONSUL_VERSION=${consul_version}
NOMAD_VERSION=${nomad_version}
DATACENTER=${datacenter}
OUTPUT_IP=${output_ip}
NODE_TYPE=${node_type}
PERSISTENT_DISK=${persistent_disk}

start_services()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true

		CHECKNETMODE=$(systemctl is-enabled NetworkManager)
		if [ $? != 0 ] ; then
			systemctl reload NetworkManager || true
			systemctl restart NetworkManager || true
		else
			systemctl restart network || true
		fi

		systemctl enable docker || true
		systemctl start docker || true
	fi

	CHECKNET=$(docker network ls | grep backend-net)
  if [ $? != 0 ] ; then
		echo "Create overlay network"
    docker network create -d overlay --subnet 10.27.0.0/16 backend-net
  fi

	echo "OK : system services enabled and started"
}

start_app()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl enable consul || true
		systemctl start consul || true
		systemctl enable nomad || true
		systemctl start nomad || true
	fi

	echo "OK : services enabled and started"
}

stop_all()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl disable docker || true
		systemctl stop docker || true
		systemctl disable nomad || true
		systemctl stop nomad || true
		systemctl disable consul || true
		systemctl stop consul || true
	fi

	echo "OK : services disabled and stoped"
}

install_packages()
{
	yum install -y -q unzip wget firewalld lvm2
}

configure_services()
{
		sed -ie s/PEERDNS=yes/PEERDNS=no/g /etc/sysconfig/network-scripts/ifcfg-eth0
		echo 'DNS1=${dns1}' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
		echo 'DNS2=${dns2}' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
		echo 'DNS3=${dns3}' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0

		echo 'supersede domain-name-servers ${dns1}, ${dns2}, ${dns3};' | tee -a /etc/dhclient.conf
}

install_docker()
{
	cat > /etc/yum.repos.d/docker.repo <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/7/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

	echo "OK : DockerRepo created"

	yum install -y -q docker-ce
	groupadd docker

	mkdir -p /etc/docker/

	# If sdb disk exist, configure it as primary storage backend for docker
	if [ -n $${PERSISTENT_DISK} ] ; then
		echo "Configure docker lvm storage"
		cat > /etc/docker/daemon.json <<EOF
{
	"cluster-store": "consul://consul.service.consul:8500",
	"cluster-advertise": "eth0:2376",
	"storage-driver": "devicemapper",
	"storage-opts": [
		"dm.directlvm_device=${persistent_disk}",
		"dm.thinp_percent=95",
		"dm.thinp_metapercent=1",
		"dm.thinp_autoextend_threshold=80",
		"dm.thinp_autoextend_percent=20",
		"dm.directlvm_device_force=false"
	]
}
EOF
	else
		echo "Configure docker file storage"
		cat > /etc/docker/daemon.json <<EOF
{
	"cluster-store": "consul://consul.service.consul:8500",
	"cluster-advertise": "eth0:2376"
}
EOF
fi

	echo "OK : Docker installed"
}

install_consul()
{
	wget -qP /tmp https://releases.hashicorp.com/consul/$${CONSUL_VERSION}/consul_$${CONSUL_VERSION}_linux_amd64.zip && unzip /tmp/consul_$${CONSUL_VERSION}_linux_amd64.zip -d /usr/bin/ && rm -f /tmp/consul_$${CONSUL_VERSION}_linux_amd64.zip

	adduser consul
	mkdir -p /etc/consul /var/consul
	chown consul. /var/consul

	cat > /etc/systemd/system/consul.service <<EOF
[Unit]
Description=Consul Agent
Wants=basic.target
After=basic.target network.target docker.service

[Service]
User=consul
Group=consul
EnvironmentFile=-/etc/sysconfig/consul
ExecStart=/usr/bin/consul agent -config-dir /etc/consul $OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

	echo "OK : Consul installed"
}

configure_consul()
{
    cat > /etc/consul/config.json <<EOF
{
    "server": false,
    "datacenter": "$${DATACENTER}",
    "data_dir": "/var/consul",
    "log_level": "INFO",
    "enable_syslog": true,
		${join},
		"bind_addr": "$${OUTPUT_IP}"
}
EOF

	echo "OK : Consul configured"
}

install_nomad()
{
	wget -qP /tmp https://releases.hashicorp.com/nomad/$${NOMAD_VERSION}/nomad_$${NOMAD_VERSION}_linux_amd64.zip && unzip /tmp/nomad_$${NOMAD_VERSION}_linux_amd64.zip -d /usr/bin/ && rm -f /tmp/nomad_$${NOMAD_VERSION}_linux_amd64.zip

	adduser nomad
	mkdir -p /etc/nomad /var/nomad
	chown nomad. /var/nomad

	usermod -G docker -a nomad

	cat > /etc/systemd/system/nomad.service <<EOF
[Unit]
Description=Nomad Agent
Wants=basic.target
After=basic.target network.target consul.service docker.service

[Service]
User=nomad
Group=nomad
EnvironmentFile=-/etc/sysconfig/nomad
ExecStart=/usr/bin/nomad agent -config /etc/nomad $OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

	echo "OK : Nomad installed"
}

configure_nomad()
{
  if [ $${NODE_TYPE} == "server" ]; then
	cat > /etc/nomad/config.hcl <<EOF
	region = "$${REGION}"
  datacenter = "$${DATACENTER}"
	data_dir = "/var/nomad"
	bind_addr = "$${OUTPUT_IP}"

  server {
      enabled = true
      bootstrap_expect = 3
  }

  consul {
      address = "127.0.0.1:8500"
  }
EOF
else
	cat > /etc/nomad/config.hcl <<EOF
	region = "$${REGION}"
  datacenter = "$${DATACENTER}"
  data_dir = "/var/nomad"
  bind_addr = "$${OUTPUT_IP}"

  client {
      enabled = true
  }
EOF
fi

	echo "OK : Nomad configured"
}

clean_install()
{
	stop_services
	rm -f /usr/bin/consul
	rm -f /etc/consul/
	rm -f /etc/systemd/system/consul.service
	rm -f /usr/bin/nomad
	rm -f /etc/nomad/
	rm -f /etc/systemd/system/nomad.service
	rm -f /etc/yum.repos.d/docker.repo

	echo "OK : Clean install"
}

do_install()
{
	install_packages
	install_docker

	configure_services
	start_services

	install_consul
	configure_consul
	install_nomad
	configure_nomad

	start_app

	cat <<EOF
************************************
Host installed successfully
************************************
EOF
}

do_install
