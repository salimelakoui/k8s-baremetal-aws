
mkdir istio
cd istio
curl -L https://istio.io/downloadIstio | sh -
mv * istio-app
cd istio-app
chmod +x bin/istioctl
sudo mv bin/istioctl /usr/local/bin/istioctl

istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system

## TODO 
# Trouver un moyen d'exposer le endoint
# gatway + kiali
# istioctl dashboard kiali
## TOODO
kubectl patch svc -n istio-system kiali --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
kubectl patch svc -n istio-system istio-ingressgateway --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'


kubectl get virtualservices   #-- there should be no virtual services
kubectl get destinationrules  #-- there should be no destination rules
kubectl get gateway           #-- there should be no gateway
kubectl get pods              #-- the Bookinfo pods should be deleted