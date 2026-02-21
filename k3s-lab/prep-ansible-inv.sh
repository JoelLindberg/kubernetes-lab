#!/bin/bash

INV_TEMPLATE="lab.ini.tmpl"
FINAL_CONFIG="ansible/inv/lab.ini"

# Extract VM IPs from `virsh guestinfo` output
K3S1_IP="$(virsh guestinfo k3s1 --interface | grep 'if.1.addr.0.addr' | awk '{ print $3 }')"
K3S2_IP="$(virsh guestinfo k3s2 --interface | grep 'if.1.addr.0.addr' | awk '{ print $3 }')"
K3S3_IP="$(virsh guestinfo k3s3 --interface | grep 'if.1.addr.0.addr' | awk '{ print $3 }')"

# Fail fast if any IP was not found
if [ -z "$K3S1_IP" ] || [ -z "$K3S2_IP" ] || [ -z "$K3S3_IP" ]; then
    echo "Error: could not resolve one or more VM IPs from 'virsh guestinfo'." >&2
    exit 1
fi

# Export for envsubst
export K3S1_IP K3S2_IP K3S3_IP

# Use 'envsubst' to create the ansible inventory file with the IP addresses of the VMs
envsubst < "$INV_TEMPLATE" > "$FINAL_CONFIG"

# generate ssh config
cat <<EOF > ansible/ssh.cfg
Host k3s1
  HostName ${K3S1_IP}
  User k3slab
  IdentityFile ~/.ssh/kubernetes-lab
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no

Host k3s2
  HostName ${K3S2_IP}
  User k3slab
  IdentityFile ~/.ssh/kubernetes-lab
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no

Host k3s3
  HostName ${K3S3_IP}
  User k3slab
  IdentityFile ~/.ssh/kubernetes-lab
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
EOF
echo "Generated ansible/inv/lab.ini and ansible/ssh.cfg"

echo "Generated Ansible inventory file at $FINAL_CONFIG"