resource "helm_release" "thanos-pre-reqs" {
  name              = "tpr"
  chart             = "thanos-pre-reqs"
  repository        = "./helm-charts"
  dependency_update = true
  values = [
    <<EOF
grafana-operator:
  enabled: true

vault-secrets-operator:
  enabled: true

  controller: 
    manager:
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 10m
          memory: 64Mi

  controller: 
    manager:
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 10m
          memory: 64Mi

  defaultAuthMethod:
    enabled: true
    namespace: default
    method: kubernetes
    mount: indico-devops-us-east-2-monitoring
    kubernetes:
      role: vault-auth-role
      tokenAudiences: ["vault"]
      serviceAccount: vault-auth

  defaultVaultConnection:
    enabled: true
    address: https://vault.devops.indico.io
    skipTLSVerify: false
    spec:
    template:
      spec:
        containers:
        - name: manager
          args:
          - "--client-cache-persistence-model=direct-encrypted"
  EOF
  ]
}

resource "helm_release" "thanos" {
  depends_on        = [helm_release.thanos-pre-reqs]
  name              = "t"
  chart             = "thanos"
  repository        = "./helm-charts"
  dependency_update = true

  values = [
    <<EOF
thanos:
  enabled: true
  existingObjstoreSecret: thanos-storage
  query:
    requests:
      memory: 64Gi
      cpu: 2000m

    tolerations:
      - effect: NoSchedule
        key: indico.io/highmem
        operator: Exists
      
  storegateway:
    enabled: true
    sharded:
      enabled: true
    persistence:
      enabled: true
      size: 500Gi
    args:
      - store
      - --log.level=info
      - --log.format=logfmt
      - --grpc-address=0.0.0.0:10901
      - --http-address=0.0.0.0:10902
      - --data-dir=/data
      - --objstore.config-file=/conf/thanos_storage.yaml

grafana:
  service:
    annotations:
      external-dns.alpha.kubernetes.io/hostname: grafana.monitoring.us-east-2.indico-devops.indico.io
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: zerossl
      external-dns.alpha.kubernetes.io/hostname: grafana.monitoring.us-east-2.indico-devops.indico.io
    labels:
      acme.cert-manager.io/dns01-solver: "true"
    hosts:
      - grafana.monitoring.us-east-2.indico-devops.indico.io
    tls:
      - secretName: t-grafana-tls
        hosts:
          - grafana.monitoring.us-east-2.indico-devops.indico.io
  admin:
    passwordKey: admin-password
    userKey: admin-user
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: Prometheus
        type: prometheus
        url: http://t-thanos-query:9090
        access: proxy
EOF
  ]
}

