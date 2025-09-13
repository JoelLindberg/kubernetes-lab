# kubernetes-lab

Learning Kubernetes. Skipping minikube as it abstracts too many details.

*A lot of the notes are mixed with copy/paste info from the official our third party sources. Trying to move with diligence but the reality is I have limited amount of time to at my disposal currently.*


## Lab 1 - kind

I will perform this lab inside of WSL2 with Docker Engine.

* Main tutorial: https://kubernetes.io/docs/tutorials/hello-minikube/
* kind: https://kind.sigs.k8s.io/docs/user/quick-start/#configuring-your-kind-cluster


## Lab 2 - k3s / Managed kubernetes in a public cloud

The goal is to next experiment with a production setup next. Managed kubernetes or k3s depending on the situation.

* k3s
    - Reqs: https://docs.k3s.io/installation/requirements
        - 2 VMs (can be run in docker): 1 master (2 CPU 2GB) and 1 node (1 CPU 512MB)
        - Database: MySQL, PostgreSQL, etcd
    - https://docs.k3s.io/quick-start
* k3d:
    - Allows to setup k3s easily in docker for development or test purposes
    - https://k3d.io/stable/



## Kubernetes components

* Node
    - Nodes are the workers that run applications
    - Kubelet (each node has a kubelet agent for managing the node and communicating with the Kubernetes control plane)
* Control Plane
    - The Control Plane coordinates the cluster
    - The Control Plane coordinates all activities in your cluster, such as scheduling applications, maintaining applications' desired state, scaling applications, and rolling out new updates.
    - Kubernetes API (https://kubernetes.io/docs/concepts/overview/kubernetes-api/)


## Tools

* kubectl
    - https://kubernetes.io/docs/tasks/tools/#kubectl
    - You must use a kubectl version that is within one minor version difference of your cluster. For example, a v1.34 client can communicate with v1.33, v1.34, and v1.35 control planes.
* Reference: https://kubernetes.io/docs/reference/kubectl/
* kuberc
    - A plugin for Kubernetes command-line tool kubectl, which allows you to convert manifests between different API versions.
    - Skipping this one for this lab, but useful to know for production maintenance

1. `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`
2. `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"`
3. `echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check`
4. `sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl`
5. `kubectl version --client` or `kubectl version --client --output=yaml`

Auto-completion for kubectl:

Bash completion already installed? `type _init_completion`
Enable kubectl completion: `echo 'source <(kubectl completion bash)' >>~/.bashrc`

Extend your alias "k" with autocompletion:
~~~~bash
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
~~~~

Reload: `source ~/.bashrc`


