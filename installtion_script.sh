#!/bin/bash
#  Author
#  Sergio Molino
#
#  This script install Entando application on EKS
#
namespace=$1
appname=$2

if [[ -z "$namespace" ]]; then
        echo "Use "$(basename "$0")" NAMESPACE";
        exit 1;
fi
if [[ -z "$appname" ]]; then
        echo "Use "$(basename "$0")" APPNAME";
        exit 1;
fi
echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Installing ingress"
echo ""
echo "##################################################################################"
echo "##################################################################################"
## Ingress EKS
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/aws/deploy.yaml
# Old version not supported anymore / does not work with entando.ingress.class: 'nginx'
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.41.2/deploy/static/provider/aws/deploy.yaml
# This works
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.49.3/deploy/static/provider/aws/deploy.yaml
### Ingress AKS
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml

echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Creating Namespace $namespace"
echo ""
echo "##################################################################################"
echo "##################################################################################"
kubectl create namespace $namespace


echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Applying Config Map"
echo ""
echo "##################################################################################"
echo "##################################################################################"

echo -e "
kind: ConfigMap
apiVersion: v1
metadata:
  name: entando-operator-config
  namespace: $namespace
data:
  entando.requires.filesystem.group.override: 'true'
  entando.ingress.class: 'nginx'
  singleHostName: '$appname.104.155.69.46.nip.io'
  entando.pod.completion.timeout.seconds: '2200'
  entando.pod.readiness.timeout.seconds: '2200'" | kubectl apply -f -


echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Creating Cluster Resources"
echo ""
echo "##################################################################################"
echo "##################################################################################"

kubectl apply -f https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v7.0.0/manifests/k8s-116-and-later/namespace-scoped-deployment/cluster-resources.yaml

echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Creating Namespace Resources"
echo ""
echo "##################################################################################"
echo "##################################################################################"

#kubectl apply -n $namespace -f https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v7.0.0/manifests/k8s-116-and-later/namespace-scoped-deployment/namespace-resources.yaml
kubectl apply -f namespace-resource-new.yaml -n $namespace
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Deploying Applicaton $appname"
echo ""
echo "##################################################################################"
echo "##################################################################################"
sleep 10
kubectl get svc -n ingress-nginx | grep LoadBalancer | awk '{print $4}' | while read HOST;do
echo -e "
apiVersion: entando.org/v1
kind: EntandoApp
metadata:
  namespace: $namespace
  name: $appname
spec:
  environmentVariables: []
  entandoAppVersion: '7.0'
  dbms: embedded
  ingressHostName: $HOST.nip.io
  standardServerImage: eap
  replicas: 1" | kubectl apply -f -; done
echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Namespace $namespace is created and $appname application is deploying"
echo "Wait around 10 minutes, when application is deployed it is available at:"
echo ""
kubectl get svc -n ingress-nginx | grep LoadBalancer | awk '{print $4}' |while read HOST;do
echo "http://$HOST.nip.io/app-builder/";done
echo ""
echo "##################################################################################"
echo "##################################################################################"
