#!/bin/bash
# Deploy Cassandra StatefulSet from cassandra.yaml, replacing _NAMESPACE_, _OTHERNAMESPACE_, _DATACENTER_ and _STORAGECLASS_ placeholders

apply () {
  context=$1
  namespace=$2
  other_namespace=$3
  datacenter=$4
  storage_class=$5

  read -p "Hit ENTER to deploy Cassandra to $context" go
  kubectl config use-context $context
  cat cassandra.yaml | sed "s/_DATACENTER_/$datacenter/g" | sed "s/_NAMESPACE_/$namespace/g" | sed "s/_OTHERNAMESPACE_/$other_namespace/g" | sed "s/_STORAGECLASS_/$storage_class/g" | kubectl create -f -
}

echo
echo "This will deploy Cassandra as a 3-node cluster in each cloud provider."
echo
read -p 'Context 1: ' context1
read -p 'Datacenter 1: ' datacenter1
read -p 'Namespace 1: ' namespace1
read -p 'Storage class 1: ' storage_class1
read -p 'Context 2: ' context2
read -p 'Datacenter 2: ' datacenter2
read -p 'Namespace 2: ' namespace2
read -p 'Storage class 2: ' storage_class2

apply $context1 $namespace1 $namespace2 $datacenter1 $storage_class1
apply $context2 $namespace2 $namespace1 $datacenter2 $storage_class2
