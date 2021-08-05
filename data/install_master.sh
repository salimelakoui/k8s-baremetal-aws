#!/bin/bash
set -o xtrace

MASTER_IP="`curl http://169.254.169.254/latest/meta-data/local-ipv4`"
MASTER_HOSTNAME="`curl http://169.254.169.254/latest/meta-data/public-hostname`"

# kub master
kubeadm config images pull
#kubeadm init "--pod-network-cidr=192.168.0.0/16"
kubeadm init --pod-network-cidr=10.244.0.0/16 --service-dns-domain "k8s" --apiserver-advertise-address $MASTER_IP
#kubeadm init --pod-network-cidr 192.168.0.0/16 --service-cidr 10.96.0.0/12 --service-dns-domain "k8s" --apiserver-advertise-address $MASTER_IP 

# for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# kub for root
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

# kub for admin
mkdir -p /home/admin/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/admin/.kube/config
sudo chown admin:admin /home/admin/.kube/config

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

# NFS
apt install -y nfs-kernel-server
mkdir /nfs-export
echo "/nfs-export               10.0.0.0/8(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
exportfs -a

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
sudo bash -c 'cat mydomain.key mydomain.crt >> /etc/ssl/private/mydomain.pem'
cat mydomain.key mydomain.crt >> /etc/ssl/private/mydomain.pem

# HA PROXY
sudo apt install -y haproxy

cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_nonlocal_bind = 1
EOF

##backup the current file
mv /etc/haproxy/haproxy.cfg{,.back}

## Edit the file
cat > /etc/haproxy/haproxy.cfg << EOF
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

sudo service haproxy restart

## TESTING

kubectl apply -f https://k8s.io/examples/service/access/backend-deployment.yaml
kubectl apply -f https://k8s.io/examples/service/access/backend-service.yaml
kubectl apply -f https://k8s.io/examples/service/access/frontend-deployment.yaml
kubectl apply -f https://k8s.io/examples/service/access/frontend-service.yaml

kubectl wait --for=condition=Available deployment/frontend  --timeout=60s
kubectl wait --for=condition=Available deployment/backend  --timeout=60s

## Edit the file
cat > /root/frontend-ingress.yml << EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: frontend
spec:
  rules:
    - host: $MASTER_HOSTNAME
      http:
        paths:
        - path: /frontend
          pathType: Prefix
          backend:
            service:
              name: frontend
              port:
                number: 80
EOF

kubectl apply -f /root/frontend-ingress.yml

## DASHBOARD


kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

kubectl wait --for=condition=Available deployment/kubernetes-dashboard -n kubernetes-dashboard  --timeout=60s

cat > /root/dashboard.yml << EOF
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

kubectl apply -f /root/dashboard.yml

kubectl wait --for=condition=Available deployment/kubernetes-dashboard -n kubernetes-dashboard  --timeout=60s

cat > /root/dashboard-ingress.yml << EOF
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

kubectl apply -f /root/dashboard-ingress.yml
kubectl create clusterrolebinding deployment-controller --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard