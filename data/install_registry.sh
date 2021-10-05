

### REGISTRY

kubectl create namespace registry

sudo cat > ~/private-registry.yml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: private-repository-k8s
  name: private-repository-k8s
  namespace: registry
spec:
  ports:
  - port: 5000
    nodePort: 31320
    protocol: TCP
    targetPort: 5000
  selector:
    app: private-repository-k8s
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-repository-k8s
  labels:
    app: private-repository-k8s
  namespace: registry
spec:
  replicas: 2
  selector:
    matchLabels:
      app: private-repository-k8s
  template:
    metadata:
      labels:
        app: private-repository-k8s
    spec:
      volumes:
      - name: certs-vol
        hostPath:
          path: /opt2/certs
          type: Directory
      - name: registry-vol
        hostPath:
          path: /opt2/registry
          type: Directory

      containers:
        - image: registry:2
          name: private-repository-k8s
          imagePullPolicy: IfNotPresent
          env:
          - name: REGISTRY_HTTP_TLS_CERTIFICATE
            value: "/certs/registry.crt"
          - name: REGISTRY_HTTP_TLS_KEY
            value: "/certs/registry.key"
          ports:
            - containerPort: 5000
          volumeMounts:
          - name: certs-vol
            mountPath: /certs
          - name: registry-vol
            mountPath: /var/lib/registry
EOF


kubectl create -f ~/private-registry.yml

