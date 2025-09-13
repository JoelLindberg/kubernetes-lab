
hello-node

~~~bash
kubectl create deployment hello-node --image=registry.k8s.io/e2e-test-images/agnhost:2.53 -- /agnhost netexec --http-port=8080
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

