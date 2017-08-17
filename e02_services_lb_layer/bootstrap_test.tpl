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
DATACENTER=${datacenter}

start_app()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl enable consul || true
		systemctl start consul || true
		systemctl enable httpd || true
		systemctl start httpd || true
	fi

	echo "OK : services enabled and started"
}

stop_all()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl disable httpd || true
		systemctl stop httpd || true
		systemctl disable consul || true
		systemctl stop consul || true
	fi

	echo "OK : services disabled and stoped"
}

install_packages()
{
	yum install -y -q unzip wget firewalld
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

	cat > /etc/consul/demo.json <<EOF
{
  	"service": {
    "name": "demo",
    "tags": ["traefik.tags=exposed"],
    "port": 80
  }
}
EOF

	echo "OK : Consul configured"
}

install_httpd()
{
	yum install -y httpd

	echo "OK : httpd installed"
}

configure_httpd()
{
	cat > /var/www/html/index.html <<EOF
	welcome to webserver : $(hostname -f)
EOF

	echo "OK : httpd configured"
}

clean_install()
{
	stop_services
	rm -f /usr/bin/consul
	rm -f /etc/consul/
	rm -f /etc/systemd/system/consul.service

	echo "OK : Clean install"
}

do_install()
{
	install_packages

	install_consul
	configure_consul
	install_httpd
	configure_httpd

	start_app

	cat <<EOF
************************************
Host installed successfully
************************************
EOF
}

do_install
