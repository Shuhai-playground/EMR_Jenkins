# Brief scope

- EKS cluster with 3 nodes(terraform)
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

- create EKS cluster with terraform
    - with lb controller installed
    - with helm installed
- setup prometheus
    
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
    
    ```jsx
    helm repo add karpenter https://charts.karpenter.sh
    
    helm upgrade --install --namespace karpenter --create-namespace \
      karpenter karpenter/karpenter \
      --version v0.16.3 \
      --set serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$(terraform output karpenter_controller_arn) \
      --set clusterName=$(terraform output eks_cluster_id) \
      --set clusterEndpoint=$(terraform output eks_endpoint) \
      --set aws.defaultInstanceProfile=$(terraform output instanceprofile_karpenter) \
      --wait
    
    helm upgrade --install --namespace karpenter --create-namespace \
      karpenter oci://public.ecr.aws/karpenter/karpenter \
      --version v0.20.0 \
      --set serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$(terraform output karpenter_controller_arn) \
      --set settings.aws.clusterName=$(terraform output eks_cluster_id) \
      --set settings.aws.clusterEndpoint=$(terraform output eks_endpoint) \
      --set settings.aws.defaultInstanceProfile=$(terraform output instanceprofile_karpenter) \
      --set settings.aws.interruptionQueueName=$(terraform output eks_cluster_id) \
      --wait
    ```
    

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

- configure tls for vault