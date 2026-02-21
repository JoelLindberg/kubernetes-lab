NODES=("k3s1" "k3s2" "k3s3")

for NODE in "${NODES[@]}"; do
    echo "Stopping $NODE via virsh..."
    virsh shutdown "$NODE"
done
