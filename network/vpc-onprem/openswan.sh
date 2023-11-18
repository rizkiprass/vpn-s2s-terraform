#!/bin/bash
# package updates
yum update -y
yum install openswan -y

# Update sysctl settings
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf

# Apply sysctl settings
sysctl -p

# Create AWS IPSec configuration file
cat <<EOL > /etc/ipsec.d/aws.conf
conn Tunnel1
  authby=secret
  auto=start
  left=%defaultroute
  leftid=<EIP-CGW>
  right=18.232.227.195
  type=tunnel
  ikelifetime=8h
  keylife=1h
  phase2alg=aes128-sha1;modp1024
  ike=aes128-sha1;modp1024
  keyingtries=%forever
  keyexchange=ike
  leftsubnet=<LOCAL NETWORK>
  rightsubnet=<REMOTE NETWORK>
  dpddelay=10
  dpdtimeout=30
  dpdaction=restart_by_peer
EOL

# Replace placeholders with your actual values
sed -i 's/<LOCAL NETWORK>/<your_local_network>/' /etc/ipsec.d/aws.conf
sed -i 's/<REMOTE NETWORK>/<remote_vpn_network>/' /etc/ipsec.d/aws.conf

echo "<your_customer_gateway_ip> <tunnel1_outside_ip_address>: PSK \"IWUo9Xyf4_G38qOjcmXFl4NNg5qCOKVw\"" >> /etc/ipsec.d/aws.secrets

systemctl start ipsec

# Restart OpenSwan to apply changes
service ipsec restart

chkconfig ipsec on

