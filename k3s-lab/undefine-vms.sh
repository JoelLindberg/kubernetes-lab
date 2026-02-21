NODES=("k3s1" "k3s2" "k3s3")

for NODE in "${NODES[@]}"; do
    echo "Undefining (and removing all storage) $NODE via virsh..."
    virsh undefine "$NODE" --remove-all-storage
done
