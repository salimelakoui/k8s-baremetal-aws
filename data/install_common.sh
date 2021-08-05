#!/bin/bash
set -o xtrace

#PARAM
K8S_VERSION="1.21.3-00"

# Updating & Upgrading
sudo apt-get update && sudo apt-get upgrade -y

# SSH
cat > /home/admin/.ssh/id_rsa <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
EOF
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZpjwpVPkZ/JGXY2o5MU6Ddj/wIld8G6nOLsxpVBmO0h/saekF6GKAgkZZ44F7xYYLG2i9rtQ7RGtlKReWHJFaPY9d52HLJpEYWAL6aCDzjSyy/vYMQG/tE7MSWcYprG9sZaNg5lNrvkt5deY4Ptxwj15StTmN2p48WxpwbwZofgsA2ZqHtf0urng0Ki0Y5venvtFoq5VzYK5NXTp9ma5TRDFZuXd/zCWE8+dq59AeuzoGkeKQVSeXz2+xyxTKlzrGKfXTK1XidihDrx/kFP9WlFLg7fopCT0gibvb0/H+admh+GgOs7GlN2mhAJyEV530So4kFgQwZLJ1L8kCfiHfPiXnu9GQzBwBIbM3YQk6NunvZIEwE5c1tMo2+E7nvu1kcJxuwjLJz3p6X4g+gAQnOr8R63FbB/bNIeRTkqA0cPxdUFKG4Fe46FG4E9ux3KTLC1MtwNL8VLDMRibvYmf1XB/wg7KN5w4n5Dx/jRxkn4rTqOK15GkH3QRsKd0A1XiLBdwtDUyNmvwpMsIfHav2pU6nEGRx+3lxy8xCeGem8vTlVP2olGzGBowg/DvSZHkWgaMaSByrE/1kQTCXO4PwDZhu1ejlcT9h+/hzABuN2IsYlER7q3GRmvXvU4DvHzPfpebFF4VnwFBovA5QW/xJExkPGzvsJhXy1RycPEu3Vw== admin@ip-172-32-4-182" | tee /home/admin/.ssh/id_rsa.pub
sudo cp /home/admin/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
sudo cp /home/admin/.ssh/id_rsa /root/.ssh/id_rsa

sudo cat /root/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
sudo chown root /root/.ssh/id_rsa.pub /root/.ssh/id_rsa /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/id_rsa.pub /root/.ssh/id_rsa /root/.ssh/authorized_keys

sudo cat /root/.ssh/id_rsa.pub | tee -a /home/admin/.ssh/authorized_keys
chown admin:admin /home/admin/.ssh/id_rsa.pub /home/admin/.ssh/id_rsa /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/id_rsa.pub /home/admin/.ssh/id_rsa /home/admin/.ssh/authorized_keys

# Inclusing extra key 
echo "${extra_key}" | tee -a /home/admin/.ssh/authorized_keys
sudo echo "${extra_key}" | tee -a /home/admin/.ssh/authorized_keys

# GENERAL
sudo apt-get -y install git htop nmap

#Docker
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list 
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo swapoff -a;
sudo echo '{ "exec-opts": ["native.cgroupdriver=systemd"] }' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# kub installation
sudo modprobe br_netfilter #Permettre à iptables de voir le trafic ponté
sudo lsmod | grep br_netfilter
sudo echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
sudo echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
sudo sysctl --system
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl

# CONVERT
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert
sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert

sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl

# kub for root
sudo echo "alias kc=kubectl" | sudo tee -a /root/.bashrc
sudo echo "alias ke=kubectl" | sudo tee -a /root/.bashrc
sudo echo "alias ka=kubeadm" | sudo tee -a /root/.bashrc
sudo echo ". /etc/bash_completion" | sudo tee -a /root/.bashrc
sudo echo 'complete -F __start_kubectl kc' | sudo tee -a /root/.bashrc
sudo echo 'set ts=2 sts=2 sw=2' | sudo tee -a /root/.vimrc

# kub for admin
echo "alias kc=kubectl" | tee -a /home/admin/.bashrc
echo "alias ke=kubelet" | tee -a /home/admin/.bashrc
echo "alias ka=kubeadm" | tee -a /home/admin/.bashrc
echo ". /etc/bash_completion" | tee -a /home/admin/.bashrc
echo 'complete -F __start_kubectl kc' | tee -a /home/admin/.bashrc
echo 'set ts=2 sts=2 sw=2' |  tee -a /home/admin/.vimrc

