#!/bin/bash
NAMESPACE="cp-portal"
TAG="v1.6.2"

echo "Deleting Kyverno policy: cp-always-pull-images-policy"
kubectl delete clusterpolicy cp-always-pull-images-policy

for DEP in $(kubectl -n $NAMESPACE get deploy -o name); do
  SHORT=$(echo $DEP | sed 's/deployment.apps\///; s/-deployment$//')
  NEW_IMG="localhost/${SHORT}:$TAG"
  echo "패치: $DEP → $NEW_IMG, imagePullPolicy=IfNotPresent"
  kubectl -n $NAMESPACE patch $DEP --type=json -p="[
    {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/image\", \"value\": \"$NEW_IMG\"},
    {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/imagePullPolicy\", \"value\": \"IfNotPresent\"}
  ]"
done
