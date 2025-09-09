#!/usr/bin/env bash

# Error: container create failed: creating `/etc/core/token`: openat2 `etc/core/token`: No such file or directory
helm pull bitnami/harbor --version 27.0.3 --untar
sed -i "" '/^[[:space:]]*- name: psc$/{
N
d
}' ./harbor/templates/core/core-dpl.yaml

sed -i '' 's|\.Values\.ingress\.core\.hostname|((index .Values.ingress.core.extraTls 0).hosts \| first)|g' ./harbor/templates/core/core-dpl.yaml
sed -i '' 's|\.Values\.ingress\.core\.hostname|(index .Values.ingress.core.extraTls 0).hosts|g' ./harbor/templates/core/core-dpl.yaml

helm package ./harbor
