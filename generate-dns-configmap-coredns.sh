#!/bin/bash
# Generate a kube-dns ConfigMap to forward DNS requests for a given namespace

apply () {
  SOURCE_CONTEXT=$1
  DEST_CONTEXT=$2
  DEST_NAMESPACE=$3
  list= 

  # Get the node IPs and port of kube-dns on the destination cluster
  kubectl config use-context $DEST_CONTEXT
  NODEPORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services kube-dns --namespace=kube-system)
  NODES=$(kubectl get nodes -o jsonpath='{ $.items[*].status.addresses[?(@.type=="InternalIP")].address }')
  for node in $NODES
  do
    list=${list:+$list }$node:$NODEPORT
  done
CONFIGMAP="---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          upstream
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
        import custom/*.override
    }
    $DEST_NAMESPACE.svc.cluster.local {
        forward . $list
    }
    import custom/*.server
"
  kubectl config use-context $SOURCE_CONTEXT
  echo "Updating ConfigMap on cluster $SOURCE_CONTEXT"
  echo "$CONFIGMAP"
  cat <<EOF | kubectl apply -f -
$CONFIGMAP
EOF
}

echo
echo "This will generate the ConfigMaps for DNS forwarding between 2 clusters"
echo
read -p 'Context 1: ' context1
read -p 'Namespace 1: ' namespace1
read -p 'Context 2: ' context2
read -p 'Namespace 2: ' namespace2

apply $context1 $context2 $namespace2
apply $context2 $context1 $namespace1
