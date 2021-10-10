#!/bin/bash

# for help
# https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04-ru
# https://github.com/OpenVPN/openvpn/blob/master/sample/sample-config-files/server.conf
# https://github.com/OpenVPN/openvpn/blob/master/sample/sample-config-files/client.conf

# Update apt repo list
apt update -y
# Install OpenVPN and packages
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install openvpn wget tar zip mc iptables-persistent netfilter-persistent -y
# Create dir for EasyRSA
mkdir -p /opt/easy-rsa
# Download and prep EasyRSA
wget -P /opt/easy-rsa https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
tar -xvzf /opt/easy-rsa/EasyRSA-3.0.8.tgz -C /opt/easy-rsa
cp -rf /opt/easy-rsa/EasyRSA-3.0.8/* /opt/easy-rsa/

# Generate EasyRSA vars
cat <<EOF > /opt/easy-rsa/vars
set_var EASYRSA_REQ_COUNTRY "RU"
set_var EASYRSA_KEY_SIZE 2048
set_var EASYRSA_REQ_PROVINCE "Moscow"
set_var EASYRSA_REQ_CITY "Moscow"
set_var EASYRSA_REQ_ORG "Azure LLC"
set_var EASYRSA_REQ_EMAIL "mail@azure.net"
set_var EASYRSA_REQ_OU "IT"
set_var EASYRSA_REQ_CN "OpenVPN"
set_var EASYRSA_CERT_EXPIRE 3650
set_var EASYRSA_DH_KEY_SIZE 2048
set_var EASYRSA_BATCH "yes"
EOF

cd /opt/easy-rsa
# Init PKI
/opt/easy-rsa/easyrsa init-pki
# Generate CA cert
/opt/easy-rsa/easyrsa build-ca nopass
# Generate server cert
/opt/easy-rsa/easyrsa build-server-full server nopass
# Generate DH cert
/opt/easy-rsa/easyrsa gen-dh
# Generate CRL
/opt/easy-rsa/easyrsa gen-crl
# Copy keys to OpenVPN
mkdir -p /etc/openvpn/keys
cp -f /opt/easy-rsa/pki/ca.crt /opt/easy-rsa/pki/crl.pem /opt/easy-rsa/pki/dh.pem /etc/openvpn/keys/
cp -f /opt/easy-rsa/pki/issued/server.crt /etc/openvpn/keys/
cp -f /opt/easy-rsa/pki/private/server.key /etc/openvpn/keys/

# Set kernel parameters
cat <<EOF >> /etc/sysctl.conf

# Enable IP forwarding
net.ipv4.ip_forward=1

# Protect MITM attacks
net.ipv4.conf.all.accept_redirects = 0

# Permit ICMP redirects
net.ipv4.conf.all.send_redirects = 0

# Permit PMTU search
net.ipv4.ip_no_pmtu_disc = 1
EOF
sysctl -p

# Prep OpenVPN logs
mkdir -p /var/log/openvpn
touch /var/log/openvpn/{openvpn-status,openvpn}.log

# Prep OpenVPN server config
mkdir -p /etc/openvpn/ccd
cat <<EOF > /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca /etc/openvpn/keys/ca.crt
cert /etc/openvpn/keys/server.crt
key /etc/openvpn/keys/server.key
dh /etc/openvpn/keys/dh.pem
crl-verify /etc/openvpn/keys/crl.pem
topology subnet
server 10.10.8.0 255.255.255.0
ifconfig-pool-persist ipp.txt
client-config-dir /etc/openvpn/ccd
push "route 10.10.0.0 255.255.0.0"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "redirect-gateway def1 bypass-dhcp"
keepalive 10 120
cipher AES-256-CBC
max-clients 10
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20
daemon
mode server
EOF

# Restart OpenVPN server
systemctl enable openvpn@server
systemctl restart openvpn@server
systemctl status openvpn@server

# Enable IP Masquerading (NAT)
iptables -t nat -A POSTROUTING -s 10.10.8.0/24 -o eth0 -j MASQUERADE

# Prep OpenVPN client configs
mkdir -p /home/${user_name}/openvpn/ready_client_conf
cat <<EOF > /home/${user_name}/openvpn/template_client_conf.txt
client
dev tun
proto udp
remote ${remote_address} 1194
user nobody
group nobody
persist-key
persist-tun
mute-replay-warnings
cipher AES-256-CBC
verb 3
mute 20
EOF

client_number=${client_count}
# Function for create client configs
create_client_conf () {
    cd /opt/easy-rsa
    /opt/easy-rsa/easyrsa build-client-full "openvpn-client-$client_number" nopass
    cp -f /home/${user_name}/openvpn/template_client_conf.txt /home/${user_name}/openvpn/ready_client_conf/openvpn-client-$client_number.ovpn
{
    echo "<ca>"; cat "/opt/easy-rsa/pki/ca.crt"; echo "</ca>"
    echo "<cert>"; awk '/BEGIN/,/END/' "/opt/easy-rsa/pki/issued/openvpn-client-$client_number.crt"; echo "</cert>"
    echo "<key>"; cat "/opt/easy-rsa/pki/private/openvpn-client-$client_number.key"; echo "</key>"
    echo "<dh>"; cat "/opt/easy-rsa/pki/dh.pem"; echo "</dh>"
} >> /home/${user_name}/openvpn/ready_client_conf/openvpn-client-$client_number.ovpn
}
# Run function by count
while [[ $client_number -ne 0 ]]; do
    create_client_conf
    echo "client_number_before=$client_number"
    client_number="$((client_number-1))"
    echo "client_number_after=$client_number"
done
# Generate CRL
/opt/easy-rsa/easyrsa gen-crl
# Copy CRL to OpenVPN
cp -f /opt/easy-rsa/pki/crl.pem /etc/openvpn/keys/
# Restart OpenVPN server
systemctl enable openvpn@server
systemctl restart openvpn@server
systemctl status openvpn@server
# Set permissions for OpenVPN client configs
chown -R ${user_name}.${user_name} /home/${user_name}/openvpn

# Set finish trigger
touch /opt/init-finished

# example for help
# Revoke cert
#/opt/easy-rsa/easyrsa revoke openvpn-client-1
