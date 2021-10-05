
MASTER_IP="`curl http://169.254.169.254/latest/meta-data/local-ipv4`"
MASTER_HOSTNAME="`curl http://169.254.169.254/latest/meta-data/public-hostname`"

INGRESS_PORT_HTTP=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}'`
INGRESS_PORT_HTTPS=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[1].nodePort}'`

ISTIO_GATEWAY_PORT_HTTP=`kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[0].nodePort}'`
ISTIO_GATEWAY_PORT_HTTPS=`kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[1].nodePort}'`

ISTIO_KALIA_PORT_HTTP=`kubectl get service -n istio-system kiali -o jsonpath='{.spec.ports[0].nodePort}'`
ISTIO_KALIA_PORT_HTTPS=`kubectl get service -n istio-system kiali -o jsonpath='{.spec.ports[1].nodePort}'`

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






frontend istio_gw_front_http
     mode http
     bind $MASTER_IP:8001
     option tcplog
     default_backend istio_gw_backend_http

frontend istio_gw_front_https
     mode tcp
     bind $MASTER_IP:8002 ssl crt /etc/ssl/private/mydomain.pem
     option tcplog
     default_backend istio_gw_backend_https

backend istio_gw_backend_http
     mode http
     balance roundrobin
     option tcp-check
     server k8s-master-0 $MASTER_IP:$ISTIO_GATEWAY_PORT_HTTP check fall 3 rise 2

backend istio_gw_backend_https
     mode tcp
     balance roundrobin
     option tcp-check
     server k8s-master-0 $MASTER_IP:$ISTIO_GATEWAY_PORT_HTTPS check fall 3 rise 2 ssl verify none







frontend istio_k_front_http
     mode http
     bind $MASTER_IP:9001
     option tcplog
     default_backend istio_k_backend_http

frontend istio_k_front_https
     mode tcp
     bind $MASTER_IP:9002 ssl crt /etc/ssl/private/mydomain.pem
     option tcplog
     default_backend istio_k_backend_https

backend istio_k_backend_http
     mode http
     balance roundrobin
     option tcp-check
     server k8s-master-0 $MASTER_IP:$ISTIO_KALIA_PORT_HTTP check fall 3 rise 2

backend istio_k_backend_https
     mode tcp
     balance roundrobin
     option tcp-check
     server k8s-master-0 $MASTER_IP:$ISTIO_KALIA_PORT_HTTPS check fall 3 rise 2 ssl verify none

EOF

sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo service haproxy restart