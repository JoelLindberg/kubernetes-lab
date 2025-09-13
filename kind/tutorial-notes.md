# Following the Hello Minikube guide with kind in WSL2

This is the scenario we end up with by following the first page **Hello Minikube** (https://kubernetes.io/docs/tutorials/hello-minikube/):

![scenario](https://github.com/joellindberg/kubernetes-lab/raw/main/kind/kubernetes-lab-kind-02.png)
hello-node



~~~bash
k create deployment hello-node --image=registry.k8s.io/e2e-test-images/agnhost:2.53 -- /agnhost netexec --http-port=8080
k get deployments.apps
k get pods
k get events
k config view

# get logs - first identify the name
k get pods
k logs hello-node-6c9b5f4b59-d8fn6

~~~


Create a Service

    By default, the Pod is only accessible by its internal IP address within the Kubernetes cluster. To make the hello-node Container accessible from outside the Kubernetes virtual network, you have to expose the Pod as a Kubernetes Service.

~~~bash
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
kubectl get services

~~~


    On cloud providers that support load balancers, an external IP address would be provisioned to access the Service. On minikube, the LoadBalancer type makes the Service accessible through the minikube service command.

Since I'm running kind and not minikube I can't run `minikube service hello-node`.

I'm instead referencing:

* https://kind.sigs.k8s.io/docs/user/loadbalancer
    - This will setup a cloud balancer
* https://metallb.io/installation/
    - This is required for the loadbalancer to be able to request an external IP to use for the services

**metallb**
~~~bash
docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}'

k apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
k apply -f metallb-config.yml
~~~

**Cloud loadbalancer**

`go install sigs.k8s.io/cloud-provider-kind@latest`

    Cloud Provider KIND runs as a standalone binary in your host and connects to your KIND cluster and provisions new Load Balancer containers for your Services. It requires privileges to open ports on the system and to connect to the container runtime.

~~~bash
k apply -f kind-cloud-lb.yml
k get svc foo-service
#Verify:
LB_IP=$(kubectl get svc/foo-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

# this should print a lot of foo bar randomly (depending on which of the pods receive the request)
for _ in {1..10}; do
  curl ${LB_IP}:5678
done
~~~


I'm using the ubuntu-troubleshooter (on the same network "kind" as the "kind" kubernetes service) primarily to access the published load balanced kubernetes services. This is to minimize any strange behaviour due to the layers between docker engine, wsl2 or the host.






## troubleshooting

Some commands I used when trying to get metallb working.

~~~bash
kubectl get pods --all-namespaces
k get service --namespace metallb-system
kubectl get svc -A | grep LoadBalancer

kubectl get svc foo-service
kubectl logs -n metallb-system deploy/controller

docker network ls
docker network inspect kind

#To force a restart of the MetalLB service (or any) in your Kubernetes cluster, especially after updating its configuration or IP pool, the cleanest way is to delete its pods—Kubernetes will automatically recreate them. This ensures the controller and speaker #components reload the latest config and reprocess any pending LoadBalancer services.

kubectl delete pod --all -n metallb-system
~~~

If access outside of WSL2 would be needed (never tried this): `kubectl port-forward --address 0.0.0.0 svc/foo-service 8080:5678`
