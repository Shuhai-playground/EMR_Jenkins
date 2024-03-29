#! /bin/bash
# this script is to rename the aws eks cluster endpoint for the k8s manifest

# K8S_HOST=$(kubectl cluster-info | awk '/Kubernetes control/{print $7}')
K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')

echo "eks endpoint is replaced as $K8S_HOST"
echo $K8S_HOST

# chmod 644 application_argo.yml

#sed -i "s/server:.*/server: $K8S_HOST/" application_argo.yml


# sed -i '' -e 's/server:.*/server: $K8S_HOST/' application_argo.yml

sed -i  '' "s|server:.*|server: $K8S_HOST|" application_argo.yml