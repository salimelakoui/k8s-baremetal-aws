
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

# INGRESS
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0-beta.1/deploy/static/provider/baremetal/deploy.yaml
kubectl wait --for=condition=Available deployment/ingress-nginx-controller -n ingress-nginx  --timeout=60s
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
