NODES=("k3s1" "k3s2" "k3s3")

for NODE in "${NODES[@]}"; do
    echo "Starting $NODE via virsh..."
    virsh start "$NODE"
done
