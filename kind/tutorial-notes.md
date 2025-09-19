# Following the Hello Minikube guide with kind in WSL2

This is the scenario we end up with by following the first page **Hello Minikube** (https://kubernetes.io/docs/tutorials/hello-minikube/):

![scenario](https://github.com/joellindberg/kubernetes-lab/raw/main/kind/kubernetes-lab-kind-02.png)
hello-node



## hello-minikube (but with kind)

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
k expose deployment hello-node --type=LoadBalancer --port=8080
k get services
~~~


    On cloud providers that support load balancers, an external IP address would be provisioned to access the Service. On minikube, the LoadBalancer type makes the Service accessible through the minikube service command.

Since I'm running kind and not minikube I can't run `minikube service hello-node`.

I'm instead setting up metallb and a cloud load balancer:

* https://metallb.io/installation/
    - This is required for the loadbalancer to be able to request an external IP to use for the services

**metallb**
~~~bash
# note the output IP
docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}'

k apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
# first update the IP range in this file based on the previous output to match Docker's internal network for kind:
k apply -f metallb-config.yml 
~~~

**Cloud loadbalancer**

* https://kind.sigs.k8s.io/docs/user/loadbalancer

~~~bash
# this obviously requires go to already be installed
go install sigs.k8s.io/cloud-provider-kind@latest
~~~

    Cloud Provider KIND runs as a standalone binary in your host and connects to your KIND cluster and provisions new Load Balancer containers for your Services. It requires privileges to open ports on the system and to connect to the container runtime.

Verify that it works:
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

metallb and cloud load balancer is now setup.

Cleanup the after the metallb and cloud load balancer setup:
~~~bash
k delete -f kind-cloud-lb.yml
~~~



Continue the kubernetes tutorial:

Cleanup the hello-node service and deployment:
~~~bash
k delete service hello-node
k delete deployment hello-node
~~~





### troubleshooting metallb deployment

Some commands I used when trying to get metallb working.

~~~bash
k get pods --all-namespaces
k get service --namespace metallb-system
k get svc -A | grep LoadBalancer

k get svc foo-service
k logs -n metallb-system deploy/controller

docker network ls
docker network inspect kind

#To force a restart of the MetalLB service (or any) in your Kubernetes cluster, especially after updating its configuration or IP pool, the cleanest way is to delete its pods—Kubernetes will automatically recreate them. This ensures the controller and speaker #components reload the latest config and reprocess any pending LoadBalancer services.

k delete pod --all -n metallb-system
~~~

If access outside of WSL2 would be needed (never tried this): `kubectl port-forward --address 0.0.0.0 svc/foo-service 8080:5678`




## Deploy an app

https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/

*Refresher: A deployment creates and runs the app while the service is then created to expose your application*

    https://kubernetes.io/docs/concepts/services-networking/service/


~~~bash
k create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
k get deployments
k get pods
~~~

The deployment did the following:
* searched for a suitable node where an instance of the application could be run (we have only 1 available node)
* scheduled the application to run on that Node
* configured the cluster to reschedule the instance on a new Node when needed


    The kubectl proxy command can create a proxy that will forward communications into the cluster-wide, private network. The proxy can be terminated by pressing control-C and won't show any output while it's running.

    The API server will automatically create an endpoint for each pod, based on the pod name, that is also accessible through the proxy.

~~~bash
k proxy # starts a proxy on 127.0.0.1:8001 which you can communicate through
curl http://localhost:8001/version # open in a new shell and contact the API

# it's now also possible to access the pods through the proxy. Let's connect to our foo and bar apps:
curl http://localhost:8001/api/v1/namespaces/default/pods/bar-app:8080/proxy/
curl http://localhost:8001/api/v1/namespaces/default/pods/foo-app:8080/proxy/
# the new app we started:
curl http://localhost:8001/api/v1/namespaces/default/pods/kubernetes-bootcamp-658f6cbd58-8hnt5:8080/proxy/
~~~



## Viewing Pods and Nodes

https://kubernetes.io/docs/tutorials/kubernetes-basics/explore/explore-intro/


