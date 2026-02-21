# lab2 - k3s

In case you'd like to replicate my steps:

My setup:
* Ubuntu 24.04
    - AppArmor enabled
* QEMU 8.2.2 (libvirt 10.0.0)
* Ansible 13.3.0 (core 2.20.2)

Prep VMs:
1. Create a new ssh key: `ssh-keygen -t ed25519 -f ~/.ssh/kubernetes-lab -C "k3s lab"`
2. `sudo bash deploy-vms.sh` \
    *sudo required for the bridged network*
3. `bash prep-ansible-inv.sh`
    *Wait 30-60 seconds before trying to run this*
4. `ansible-playbook -i inv/lab.ini playbooks/hosts.yml -u k3slab -b`
5. Optional: `cd ansible && ansible -i inv/lab.ini -u k3slab -b -m shell -a 'dnf upgrade -y' all` \
    *This step will take a while and should possibly be followed up with a reboot (and QEMU VMs power off by default with a reboot)*

*If you are running AppArmor then you should have a decent isolation between the QEMU service and your home folder thanks to both AppArmor and QEMU even when you run `sudo bash deploy-vms.sh`.*

Deploy k3s:
6. `ansible-playbook -i inv/lab.ini playbooks/site.yml -u k3slab -b` \
    *Run from the ansible/ folder*

It took roughly 30-45 minutes after the above steps had run before the cluster nodes *calmed* in terms of CPU and I/O usage. After that it became a usable cluster to continue experimenting with. Temporary increase of timeout values set in config.yaml for this reason.

Manage VMs:
7. SSH to a specific node: `ssh -F ssh.cfg k3s1`


## Make

This will perform the above.

1. Bring everything up: `make`
2. To tear everything down and start over: `bash stop-vms.sh; sleep 30; bash undefine-vms.sh`


## The "root-powered" script still can't touch your home folder (in case that would worry you):

**The "User Switch" (DAC Security):**

Even though you run the script with sudo, the Libvirt daemon (libvirtd) is smart. When it starts a QEMU process, it immediately drops privileges.

* It changes the "owner" of the VM process from root to a special user (usually libvirt-qemu or qemu).

**AppArmor: The "Invisible Jail"**

Ubuntu 24.04 uses a very strict AppArmor profile for QEMU.

* AppArmor doesn't care if you are root. It looks at the program (/usr/bin/qemu-system-x86_64) and checks its "profile."
* The QEMU profile specifically forbids the emulator from reading or writing anywhere except authorized paths like /var/lib/libvirt/images.
* Even if you manually gave the libvirt-qemu user permissions to your home folder, AppArmor would step in and block the access because your home folder isn't an "allowed path" in the security manifest.



## k3s

Uninstall: `/usr/local/bin/k3s-uninstall.sh`

### Logging

* When running with openrc, logs will be created at `/var/log/k3s.log.`
* When running with systemd, logs will be created in `/var/log/syslog` and viewed using `journalctl -u k3s` (or `journalctl -u k3s-agent` on agents).




## qemu + virt-manager notes

* `apt install qemu-system`
* `apt install virt-manager`

To allow virsh and the graphical Virtual Machine Manager to run as my normal user while still being able to access `qemu:///system`: \
`sudo usermod -aG libvirt $USER`


VM images should be moved to: `/var/lib/libvirt/images/`

* virsh list --all
* virsh guestinfo \<vm name\>
* virsh undefine \<vm name\> --remove-all-storage` (delete everything)
* virsh destroy \<vm name\> (destroy (stop) a domain)
* virsh start/shutdown (start / gracefully shutdown)

QEMU creates a VM as a separate process, so you can check the CPU usage by using 'top'. In libvirt terminology, a Domain is the VM itself. On your host OS, that domain is manifested as a single QEMU process.

If you give a VM 4 vCPUs, you won't see 4 separate processes in top. Instead, you will see one process that spawns multiple threads (one for each vCPU, plus threads for I/O and graphics).

### Using top Effectively

When you run top, you are seeing the total CPU consumption of that VM from the host's perspective.

* The "Over 100%" Rule: If your VM has 2 vCPUs and both are pinned at 100% inside the guest, top on your host will show the QEMU process using 200% CPU.
* Steal Time & Overhead: If the VM is using 10% CPU for its own tasks, but top shows 15%, that extra 5% is the "virtualization tax"—the host spending effort emulating hardware or handling network packets for that guest.

If you want to see which specific vCPU inside your AlmaLinux VM is working the hardest, use top and then:

* Press `H` to enable "Threads" mode.
* You will now see the individual vCPU threads of the QEMU process.
* Look at the COMMAND column; you'll often see the specific thread IDs assigned to the guest's processors.


You could also consider using virt tooling:

sudo apt install virt-top
virt-top

It looks just like top, but instead of PIDs, it lists Domain Names and shows you:

* Memory actually used by the guest.
* CPU % relative to the VM's capacity.
* Disk and Network I/O per VM.
