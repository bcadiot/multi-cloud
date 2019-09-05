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

start_app()
{
	if [ -d /run/systemd/system ] ; then
		echo "Enable and start services"
		systemctl daemon-reload || true
		systemctl enable kraken || true
		systemctl start kraken || true
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
		systemctl disable kraken || true
		systemctl stop kraken || true
	fi

	echo "OK : services disabled and stoped"
}

install_packages()
{
	yum install -y -q unzip wget firewalld httpd git
}

configure_services()
{
		sed -ie s/PEERDNS=yes/PEERDNS=no/g /etc/sysconfig/network-scripts/ifcfg-eth0

		if [ ${cloud} == "gcp" ] ; then
			# DHCLIENT_PATH=/etc/dhclient.conf
			echo 'DNS1=${dns1}' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
			echo 'DNS2=${dns2}' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
			echo 'DNS3=${dns3}' | tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
			# echo 'supersede domain-name-servers ${dns1}, ${dns2}, ${dns3};' | tee -a $${DHCLIENT_PATH}
			systemctl reload NetworkManager || true
			systemctl restart NetworkManager || true
		fi

		if [ ${cloud} == "aws" ] ; then
			# DHCLIENT_PATH=/etc/dhcp/dhclient.conf
			echo 'supersede domain-name-servers ${dns1}, ${dns2}, ${dns3};' | tee -a /etc/dhcp/dhclient.conf
			systemctl restart network || true
		fi
}

install_meteor()
{
	adduser kraken
	mkdir /var/kraken
	chown kraken. /var/kraken

	export HOME=/home/kraken
	su - kraken -c "curl https://install.meteor.com/ | sh"

	firewall-cmd --add-port=80/tcp
	firewall-cmd --permanent --add-port=80/tcp
  # ExecStart=/usr/local/bin/meteor --port 80 --allow-superuser

	mv /tmp/kraken.tgz /var/kraken
	cd /var/kraken
	tar zxvf kraken.tgz
	chown kraken. -R /var/kraken
	su - kraken -c "cd /var/kraken/app && /home/kraken/.meteor/meteor npm install --save babel-runtime"

	cat > /etc/systemd/system/kraken.service <<EOF
[Unit]
Description=Kraken App
Wants=basic.target
After=basic.target network.target

[Service]
User=kraken
Group=kraken
WorkingDirectory=/var/kraken/app
ExecStart=/home/kraken/.meteor/meteor --port 3000
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

	echo "OK : Kraken installed"
}

configure_meteor()
{
	setsebool -P httpd_can_network_connect 1

    cat > /etc/httpd/conf.d/kraken.conf <<EOF
<VirtualHost *:80>
	# Reverse-Proxy
	ProxyPass / http://localhost:3000/
	ProxyPassReverse / http://localhost:3000/
	ProxyPreserveHost on

	ErrorLog /var/log/httpd/kraken_error.log
	CustomLog /var/log/httpd/kraken_access.log combined
</VirtualHost>
EOF

	echo "OK : Kraken configured"
}

clean_install()
{
	stop_services
	rm -f /usr/local/bin/meteor
	rm -f /etc/httpd/conf.d/kraken.conf
	rm -f /etc/systemd/system/kraken.service

	echo "OK : Clean install"
}

do_install()
{
	install_packages

	configure_services

	install_meteor
	configure_meteor

	start_app

	cat <<EOF
************************************
Host installed successfully
************************************
EOF
}

do_install
