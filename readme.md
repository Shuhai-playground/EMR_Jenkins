# Brief scope

- EKS cluster with 2 nodes(terraform)
- Prerequisites
    - Helm
    - load balancer
    - 
- Jenkins on eks
- vault on eks
- Monitoring: prometheus
    - HPA with prometheus
    - CA with prometheus
    - VPA with prometheus
- CICD
    - CI: Jenkins
    - CD: ArgoCD
- EMR
- Service mesh with Istio

# Steps

## create EKS cluster with terraform

- with lb controller installed
- with helm installed

## setup prometheus

### prometheus(Kube-prometheus-stack)

remark: use [helm-charts](https://github.com/prometheus-community/helm-charts)/[charts](https://github.com/prometheus-community/helm-charts/tree/main/charts)/**kube-prometheus-stack**

- setup RBAC for prometheus operator and prometheus (`no need to setup. originally it is good.`.)
    - cluster role
    - cluster role binding
    - setup the service account that I prepare in the values from prometheus helm
    - apply the yml file to create the cluster role
- install the prometheus(`Kube-prometheus-stack`) with helm

```jsx

helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts

helm search repo kube-prometheus-stack --max-col-width 23

helm install monitoring \
prometheus-community/kube-prometheus-stack \
--values ./Prometheus/prometheus_values.yml \
--version 42.3.0 \
--namespace monitoring \
--create-namespace
```

     Remark:

```jsx
helm show values prometheus-community/kube-prometheus-stack
```

§—————————————————————————————————————————————————-

skip (because node exporter is also configured in prometheus-kube-stack..)

§—————————————————————————————————————————————————-

### prometheus node exporter

- install it with helm
- values
    - servicecaccount
    - servicemonitorselector.matchexpressions
    - service
        - labels
            - <label setup in service monitor> # with this enable the prometheus to find it
    - service monitor
    
    ```jsx
    helm install node-exporter prometheus-community/prometheus-node-exporter \
    --namespace monitoring \
    --values ./Prometheus/prometheus-node-exporter/values.yml
    ```
    

§—————————————————————————————————————————————————-

## For configuring Http-request metrics

- install `prometheus adaptor` (to read the custom metrics by other k8s service)
    
    to be setup:
    
    - namespace
    - prometheus_url
    
    ```jsx
    helm install custom-metrics prometheus-community/prometheus-adapter \
    --namespace monitoring \
    --version 3.4.2 \
    --values Prometheus/prometheus-adapter/values.yml
    
    ```
    
- write configmap for the metrics query for prometheus-adapter
- setup `custom metrics api`
    - rbac (enable [custom.metrics.k8s.io](http://custom.metrics.k8s.io/))
    - apiservice

## For configuring cpu metrics

- install `cadisor`
    - namespace
    - service monitor(match the namespace label)
    - create metrics api
        - apiservice ([metrics.k8s.io](http://metrics.k8s.io/))
        - rbac

## Configure Karpenter for CA

- provision the service account for Karpenter
    - iam role
    - assumed iam_policy with oidc pointing to the service account
    - attach the iam policy
- create `iam instance profile` to enable Karpenter can work on ec2 instance
    - link to the role created above
- install helm chart with command
    - release name `cannot` be karpenter
    - the annotation should be:“serviceAccount.annotations.`"eks\.amazonaws\.com/role-arn"`”
    
    ```jsx
    helm upgrade --install karpenter-controller oci://public.ecr.aws/karpenter/karpenter --version v0.20.0 --namespace karpenter --create-namespace \
      --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$KARPENTER_IAM_ROLE_ARN \
      --set settings.aws.clusterName=$CLUSTER_NAME \
      --set settings.aws.clusterEndpoint=$CLUSTER_ENDPOINT \
      --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-$INSTANCE_PROFILE \
      --set settings.aws.interruptionQueueName=$CLUSTER_NAME \
      --wait
    
    ```
    
    [https://github.com/aws/karpenter/issues/3014](https://github.com/aws/karpenter/issues/3014)
    

to output profile arn

```yaml
aws iam list-instance-profiles --query 'InstanceProfiles[?contains(InstanceProfileName, `my-node-group`)].Arn'
```

Terraform installation

[Getting Started with Terraform](https://karpenter.sh/v0.20.0/getting-started/getting-started-with-terraform/)

Remark: how to check the instance profile of the nodes

```yaml
aws eks describe-nodegroup --cluster-name demo --nodegroup-name private_nodes | jq '.nodegroup.instanceProfileArn'

aws iam list-instance-profiles --query 'InstanceProfiles[?contains(InstanceProfileName, `eks`)].Arn' | sed -n '2p' | sed -n 's/\s*\(.*\)\s*/\1/p'
```

### Notes for karpenter configuration

- add tag to private subnet for node scaling
    - tag: "[karpenter.sh/discovery](http://karpenter.sh/discovery)" = "true"
- add tag to security group of the node group
    - tag: "[karpenter.sh/discovery](http://karpenter.sh/discovery)" = {cluster_name}

## Configure nginx controller for ingress

- use helm
    - chart:
    
    [ingress-nginx 4.4.0 · kubernetes/ingress-nginx](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx)
    
- deploy the helm
    
    ```jsx
    helm install ingress-controller ingress-nginx/ingress-nginx \
    --namespace ingress \
    --version 4.4.0 \
    --values ingress-controller/values.yml
    
    ```
    

## Configure TLS

- get the `cert-manager` installed
    - create namespace for cert-manager (remark: with prometheus label)
    - use helm  `jetstack/cert-manager`
    
    ```jsx
    helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.5.3 \
    --values TLS/cert-manager/values.yml
    ```
    
    or just download the cert-manager via kubectl
    
    ```jsx
    kubectl apply --validate=false -f TLS/cert-manager/cert-manager.yaml -n cert-manager
    ```
    

- configure the certificate for ingress
    - certificate issuer
        - the `ingress class` need to match , use command to check it `kubectl get ingressclass`
    - certificate ( `it is not needed when annotations has been made on ingress`)
- configure the ingress
    - to pass the letsentcrypt, there is only 1 option, it is to pass the `DNS1` challenge.
        - configure `route53` for records and host zone

- test the ingress with tls certificate
    - make sure in the ingress, the `annotations` has this:
        
        ```jsx
        cert-manager.io/issuer: letsencrypt-cluster-issuer
        ```
        
    
    ```jsx
    kubectl apply -f TLS/ingress-cert
    kubectl apply ingress-controller/test_ingress
    ```
    

## Configure vault

- configure a backend for vault → `consul`
    - install consul using helm
        
        ```jsx
        helm install consul hashicorp/consul \
          --namespace vault \
          --version 0.39.0 \
          -f vault/consul_values.yml 
        ```
        
- configure tls for vault
    - create tls secret in k8s
    
    (the certs are only in my own computer.)
    
    ```jsx
    kubectl -n vault create secret tls tls-ca \
     --cert ../tls/ca.pem  \
     --key ../tls/ca-key.pem
    ```
    
    ```jsx
    kubectl -n vault create secret tls tls-server \
      --cert ../tls/vault.pem \
      --key ../tls/vault-key.pem
    ```
    
    - install vault with helm
        - values
            - tls
            - injector
            - server
            - readinessProbe
            - LivenessProbe
            - extraEnvironmentVar:
                - VAULT_CACERT:/vault/userconfig/tls-ca/tls.crt
            - extraVolumes
                - secret for tls-server
                - secret for tls-ca
            - ha (run vault in the HA mode)
                - config
                    - ui = true
                    - set the address
                    - tls_disable
                    - tls_cert_file
                    - tlf_key_file
                - storage
                    - consul
                    - path
                    - address
        
        ```jsx
        helm install vault hashicorp/vault \
          --namespace vault \
          --version 0.19.0 \
          -f vault/values.yml 
        ```
        
        ## Quick installation for testing
        
        ```jsx
        helm install vault hashicorp/vault \
            --set='server.ha.enabled=true' \
            --set='server.ha.raft.enabled=true' \
        		--version 0.23.0
        		--namespace vault
        ```
        

## Provision vault

- init the vault
    
    ```jsx
    # sit into the vault pod
    kubectl exec -it pod/vault-0 -n vault -- sh
    
    # initiation
    vault operator init
    
    # save all the key
    
    # unseal
    vault operator unseal
    ```
    
- enable kubernetes injector
    
    ```jsx
    kubectl -n vault exec -it vault-0 -- sh 
    
    vault login
    vault auth enable kubernetes
    ```
    
    ### 3 things to configure auth-kubernetes on vault
    
    - Prerequisites
        - create a role with cluster role binding on the `system:auth-delegator`
            
             
            
            ```jsx
            apiVersion: v1
            kind: ServiceAccount
            metadata:
              name: vault-auth
              namespace: default
            ---
            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
              name: role-tokenreview-binding
              namespace: default
            roleRef:
              apiGroup: rbac.authorization.k8s.io
              kind: ClusterRole
              name: system:auth-delegator
            subjects:
            - kind: ServiceAccount
              name: vault-auth
              namespace: default
            ```
            
        - create a secret to store all the credential for kubernetes auth configuration
            
            ```jsx
            apiVersion: v1
            kind: Secret
            metadata:
              name: vault-auth-secret
              annotations:
                kubernetes.io/service-account.name: vault-auth
            type: kubernetes.io/service-account-token
            ```
            
    1. host address: 
        
        ```yaml
        kubectl config view --raw --minify --flatten \
            --output 'jsonpath={.clusters[].cluster.server}'
        
        export SA_SECRET_NAME=$(kubectl config view --raw --minify --flatten \
            --output 'jsonpath={.clusters[].cluster.server}')
        ```
        
    2. JWT_token
        
        ```yaml
        export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME \
            --output 'go-template={{ .data.token }}' | base64 --decode)
        ```
        
    3. CA.crt
        
        ```yaml
        export SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
            --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
        ```
        
    
    Remark:
    
    to get the kubernetes host name
    
    ```jsx
    kubectl cluster-info
    
    # or
    
    kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
    ```
    
    to test the kubernetes configuration on vault
    
    <aside>
    💡
    
    vault write auth/kubernetes/role/example \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=default \
    token_policies=myapp-kv-ro \
    ttl=24h
    
    </aside>
    
    ```jsx
    curl --request POST --data '{"jwt": "'"$SA_JWT_TOKEN"'", "role": "example"}' http://localhost:8200/ui/vault/access/kubernetes/login
    ```
    

## ArgoCD

- installation
    - with yaml file with namespace in `argocd`