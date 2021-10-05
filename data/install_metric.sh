
### METRICS
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

cat > ~/metric-patch.yaml << EOF
spec:
  template:
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        name: metrics-server   
EOF

kubectl patch deploy -n kube-system metrics-server --patch "$(cat ~/metric-patch.yaml)"