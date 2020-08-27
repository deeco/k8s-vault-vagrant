#!/bin/sh
echo vagrant up and install consul and vault into kubernetes cluster
vagrant up
export KUBECONFIG=$PWD/kubernetes-setup/kubevagrantconfig/k8s-master/home/vagrant/.kube/config
kubectl patch nodes k8s-master -p '{"spec":{"taints":[]}}'
kubectl label nodes k8s-node-1 nodename=node1
kubectl label nodes k8s-node-2 nodename=node2
echo get all resources
sleep 20
kubectl get all --all-namespaces
kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl apply -f namespaces/consul_namespace.yaml
kubectl apply -f namespaces/app_namespaces.yaml
kubectl apply -f namespaces/vault_namespace.yaml
kubectl apply -f storage/storageclass.yaml
kubectl apply -f storage/consulpv.yaml
kubectl apply -f storage/vaultpv.yaml
cfssl gencert -initca consul_install/ca/ca-csr.json | cfssljson -bare consul_install/certs/ca
cfssl gencert -ca=consul_install/certs/ca.pem -ca-key=consul_install/certs/ca-key.pem -config=consul_install/ca/ca-config.json -profile=default consul_install/ca/consul-csr.json | cfssljson -bare consul_install/certs/keys/consul
GOSSIP_ENCRYPTION_KEY=$(consul keygen)
kubectl create secret generic consul -n consul --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" --from-file=consul_install/certs/ca.pem --from-file=consul_install/certs/keys/consul.pem --from-file=consul_install/certs/keys/consul-key.pem
cfssl gencert -initca vault_setup/ca/ca-csr.json | cfssljson -bare vault_setup/certs/ca
cfssl gencert -ca=vault_setup/certs/ca.pem -ca-key=vault_setup/certs/ca-key.pem -config=vault_setup/ca/ca-config.json -profile=default vault_setup/ca/vault-csr.json | cfssljson -bare vault_setup/certs/keys/vault
GOSSIP_ENCRYPTION_KEY_VAULT=$(consul keygen)
kubectl create secret generic vault -n vault --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY_VAULT}" --from-file=vault_setup/certs/ca.pem --from-file=vault_setup/certs/keys/vault.pem --from-file=vault_setup/certs/keys/vault-key.pem
kubectl create configmap consul -n consul --from-file=consul_install/configs/server.json
kubectl create configmap vault -n vault --from-file=vault_setup/configs/server.json
kubectl create -f consul_install/services/consul.yaml
kubectl create -f vault_setup/services/vault.yaml
kubectl apply -f consul_install/serviceaccounts/consul.yaml
kubectl apply -f vault_setup/serviceaccounts/vault.yaml
kubectl apply -f consul_install/clusterroles/consul.yaml
kubectl apply -f vault_setup/clusterroles/vault.yaml
pause 20
kubectl create -f consul_install/statefulsets/consul.yaml
#kubectl create -f vault_setup/statefulsets/vault.yaml

#helm repo add hashicorp https://helm.releases.hashicorp.com

#helm install consul hashicorp/consul -f consul-helm/values.yaml --namespace consul --set global.name=consul
#sleep 20
#kubectl port-forward services/consul-ui 8888:80 -n consul8:80 -n consul
kubectl get all --all-namespaces
