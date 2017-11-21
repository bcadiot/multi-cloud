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
CONSUL_VERSION=${consul_version}
TRAEFIK_VERSION=${traefik_version}
DATACENTER=${datacenter}
OUTPUT_IP=${output_ip}
DOMAIN=${domain}

start_services()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl reload NetworkManager || true
		systemctl restart NetworkManager || true
		systemctl enable dnsmasq || true
		systemctl start dnsmasq || true
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
		systemctl enable traefik || true
		systemctl start traefik || true
	fi

	echo "OK : services enabled and started"
}

stop_all()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl disable dnsmasq || true
		systemctl stop dnsmasq || true
		systemctl disable traefik || true
		systemctl stop traefik || true
		systemctl disable consul || true
		systemctl stop consul || true
	fi

	echo "OK : services disabled and stoped"
}

install_packages()
{
	yum install -y -q unzip wget firewalld dnsmasq
}

configure_services()
{
		cat > /etc/dnsmasq.d/10-consul.conf <<EOF
		server=/consul/127.0.0.1#8600
		server=169.254.169.254
EOF

		sed -ie s/PEERDNS=yes/PEERDNS=no/g /etc/sysconfig/network-scripts/ifcfg-eth0
		echo 'DNS1=127.0.0.1' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
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
		"node_name": "${node_name}",
		${join},
		"bind_addr": "$${OUTPUT_IP}"
}
EOF

	echo "OK : Consul configured"
}

install_traefik()
{
	wget -qP /usr/bin https://github.com/containous/traefik/releases/download/v$${TRAEFIK_VERSION}/traefik_linux-amd64 && mv /usr/bin/traefik_linux-amd64 /usr/bin/traefik && chmod +x /usr/bin/traefik

	mkdir -p /etc/traefik /var/traefik

	cat > /etc/systemd/system/traefik.service <<EOF
[Unit]
Description=Traefik Agent
Wants=basic.target
After=basic.target network.target consul.service docker.service

[Service]
User=root
Group=root
EnvironmentFile=-/etc/sysconfig/traefik
ExecStart=/usr/bin/traefik --configFile=/etc/traefik/traefik.toml
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

	echo "OK : traefik installed"
}

configure_traefik()
{
	cat > /etc/traefik/traefik.toml <<EOF
	defaultEntryPoints = ["http"]

	[entryPoints]
	  [entryPoints.http]
	  address = ":80"

	[web]
	  address = ":8080"

	[consulCatalog]
	  endpoint = "127.0.0.1:8500"
	  watch = true
	  domain = "$${DOMAIN}"
	  prefix = "traefik"
		constraints = ["tag==exposed"]
EOF

	echo "OK : Traefik configured"
}

clean_install()
{
	stop_services
	rm -f /usr/bin/consul
	rm -f /etc/consul/
	rm -f /etc/systemd/system/consul.service
	rm -f /usr/bin/traefik
	rm -f /etc/traefik/traefik.toml
	rm -f /etc/systemd/system/traefik.service

	echo "OK : Clean install"
}

do_install()
{
	install_packages

	configure_services
	start_services

	install_consul
	configure_consul
	install_traefik
	configure_traefik

	start_app

	cat <<EOF
************************************
Host installed successfully
************************************
EOF
}

do_install
