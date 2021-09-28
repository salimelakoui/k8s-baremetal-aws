
MASTER_IP="`curl http://169.254.169.254/latest/meta-data/local-ipv4`"
MASTER_HOSTNAME="`curl http://169.254.169.254/latest/meta-data/public-hostname`"

# kub master
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --service-dns-domain "k8s" --apiserver-advertise-address $MASTER_IP

# for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# kub for root
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

# install Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# NODES
MASTER_TOKEN_1="`kubeadm token create`"

echo "Installing into ${ip_node_1} master $MASTER_IP with Token $MASTER_TOKEN_1"
ssh -o "StrictHostKeyChecking no" root@${ip_node_1} "kubeadm join --discovery-token-unsafe-skip-ca-verification --token=$MASTER_TOKEN_1 $MASTER_IP:6443"
ssh -o "StrictHostKeyChecking no" root@${ip_node_2} "kubeadm join --discovery-token-unsafe-skip-ca-verification --token=$MASTER_TOKEN_1 $MASTER_IP:6443"
ssh -o "StrictHostKeyChecking no" root@${ip_node_3} "kubeadm join --discovery-token-unsafe-skip-ca-verification --token=$MASTER_TOKEN_1 $MASTER_IP:6443"

# HELM
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install -y apt-transport-https
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0-beta.1/deploy/static/provider/baremetal/deploy.yaml
kubectl wait --for=condition=Available deployment/ingress-nginx-controller -n ingress-nginx  --timeout=60s
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

INGRESS_PORT_HTTP=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}'`
INGRESS_PORT_HTTPS=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[1].nodePort}'`

# SSL
# Generate a unique private key (KEY)
# Generating a Certificate Signing Request (CSR)
openssl req -new -sha256 -newkey rsa:2048 -nodes -out mydomain.csr -keyout mydomain.key -subj "/C=FR/ST=test/L=test/O=test/OU=test/CN=test"
# Creating a Self-Signed Certificate (CRT)
openssl x509 -req -days 365 -in mydomain.csr -signkey mydomain.key -out mydomain.crt
# Append KEY and CRT to mydomain.pem
sudo cat mydomain.key mydomain.crt | sudo tee -a /etc/ssl/private/mydomain.pem

# HA PROXY
sudo apt install -y haproxy

echo "net.ipv4.ip_nonlocal_bind = 1" | sudo tee -a /etc/sysctl.conf

##backup the current file
sudo mv /etc/haproxy/haproxy.cfg{,.back}

## Edit the file
sudo cat > /tmp/haproxy.cfg << EOF
global
     user haproxy
     group haproxy
     log /dev/log local0 debug
     
defaults
     mode http
     log global
     retries 2
     timeout connect 3000ms
     timeout server 5000ms
     timeout client 5000ms

frontend front_http
     mode http
     bind $MASTER_IP:80
     option tcplog
     default_backend backend_http

frontend front_https
     mode tcp
     bind $MASTER_IP:443 ssl crt /etc/ssl/private/mydomain.pem
     option tcplog
     default_backend backend_https

backend backend_http
     mode http
     balance roundrobin
     option tcp-check
     server k8s-master-0 $MASTER_IP:$INGRESS_PORT_HTTP check fall 3 rise 2

backend backend_https
     mode tcp
     balance roundrobin
     option tcp-check
     server k8s-master-0 $MASTER_IP:$INGRESS_PORT_HTTPS check fall 3 rise 2 ssl verify none

EOF

sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo service haproxy restart

## DASHBOARD
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

kubectl wait --for=condition=Available deployment/kubernetes-dashboard -n kubernetes-dashboard  --timeout=60s

cat > ~/dashboard.yml << EOF
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
        - name: kubernetes-dashboard
          image: kubernetesui/dashboard:v2.2.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8443
              protocol: TCP
          args:
            - --auto-generate-certificates
            - --enable-skip-login
            - --disable-settings-authorizer
            #- --enable-insecure-login
            #- --insecure-bind-address=0.0.0.0
            - --namespace=kubernetes-dashboard
          volumeMounts:
            - name: kubernetes-dashboard-certs
              mountPath: /certs
              # Create on-disk volume to store exec logs
            - mountPath: /tmp
              name: tmp-volume
          livenessProbe:
            httpGet:
              scheme: HTTPS
              path: /
              port: 8443
            initialDelaySeconds: 30
            timeoutSeconds: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      volumes:
        - name: kubernetes-dashboard-certs
          secret:
            secretName: kubernetes-dashboard-certs
        - name: tmp-volume
          emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
EOF

kubectl apply -f ~/dashboard.yml

kubectl wait --for=condition=Available deployment/kubernetes-dashboard -n kubernetes-dashboard  --timeout=60s

cat > ~/dashboard-ingress.yml << EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  name: dashboard
  namespace: kubernetes-dashboard
spec:
  rules:
  - host: $MASTER_HOSTNAME
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: kubernetes-dashboard
              port:
                number: 443        
EOF

kubectl apply -f ~/dashboard-ingress.yml
kubectl create clusterrolebinding deployment-controller --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard


### REGISTRY

sudo cat > ~/private-registry.yml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: private-repository-k8s
  name: private-repository-k8s
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
spec:
  replicas: 1
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

