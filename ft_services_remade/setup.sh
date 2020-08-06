#! /bin/bash

export MINIKUBE_ACTIVE_DOCKERD=minikube
export MINIKUBE_HOME=/Users/yarab/goinfre

# Ensure minikube is launched
if ! minikube status >/dev/null 2>&1
then
    echo "\033[1;31m->\033[0;31m Minikube is not launched. Starting now... \n"
    minikube start --driver=virtualbox
    minikube addons enable metrics-server
    # minikube addons enable ingress
		minikube addons enable dashboard
		Kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
		kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
		kubectl create secret generic metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
fi

kubectl apply -f srcs/metallb-config.yaml
eval $(minikube docker-env)

echo "\033[1;34m"
sleep 1
echo "build nginx"
docker build -t service-nginx srcs/nginx > /dev/null
sleep 1
echo "build ftps"
docker build -t service-ftps srcs/ftps > /dev/null



echo "\033[0;34m"
echo "apply nginx"
kubectl apply -f srcs/nginx/nginxsecret.yaml > /dev/null
sleep 1
kubectl create configmap nginxconfigmap --from-file=./srcs/nginx/default.conf --from-file=./srcs/nginx/proxy.conf > /dev/null
sleep 1
kubectl apply -f srcs/nginx/nginx.yaml > /dev/null
sleep 1
kubectl apply -f srcs/nginx/nginx.yaml > /dev/null
sleep 1
echo "apply ftps"
kubectl apply -f srcs/ftps > /dev/null
sleep 1
kubectl apply -f srcs/ftps > /dev/null
sleep 1

echo "\033[1;34m"
echo "build mysql"
docker build -t service-mysql srcs/mysql > /dev/null
sleep 1
echo "\033[0;34m"
echo "apply mysql"
kubectl apply -f srcs/mysql/mysql.yaml > /dev/null
sleep 1
kubectl apply -f srcs/mysql/mysql.yaml > /dev/null
sleep 1
echo "\033[1;34m"
echo "build phpmyadmin"
docker build -t service-phpmyadmin srcs/phpmyadmin > /dev/null
sleep 1
echo "\033[0;34m"
echo "apply phpmyadmin"
kubectl apply -f srcs/phpmyadmin/phpmyadmin.yaml > /dev/null
sleep 1
kubectl apply -f srcs/phpmyadmin/phpmyadmin.yaml > /dev/null
sleep 1
echo "\033[1;34m"
echo "build wordpress"
docker build -t service-wordpress srcs/wordpress > /dev/null
sleep 1
echo "\033[0;34m"
echo "apply wordpress"
kubectl apply -f srcs/wordpress/wordpress.yaml > /dev/null
sleep 1
kubectl apply -f srcs/wordpress/wordpress.yaml > /dev/null
sleep 1

echo "\033[1;34m"
echo "build telegraf"
docker build -t service-telegraf srcs/telegraf > /dev/null
sleep 1
echo "\033[0;34m"
echo "apply telegraf"
kubectl apply -f srcs/telegraf> /dev/null
sleep 1
kubectl apply -f srcs/telegraf> /dev/null
sleep 1

echo "\033[1;34m"
echo "build influxdb"
docker build -t service-influxdb srcs/influxdb > /dev/null
sleep 1
echo "\033[0;34m"
echo "apply influxdb"
kubectl apply -f srcs/influxdb > /dev/null
sleep 1
kubectl apply -f srcs/influxdb > /dev/null
sleep 1


echo "\033[1;34m"
sleep 1
echo "build grafana"
docker build -t service-grafana srcs/grafana > /dev/null
echo "\033[0;34m"
echo "apply grafana"
kubectl apply -f srcs/grafana > /dev/null
sleep 1
kubectl apply -f srcs/grafana > /dev/null
sleep 1

echo "minikube dashboard : "
minikube dashboard & 

kubectl get all

echo "\033[1;34m"
echo "nginx page : "
echo "http://192.168.99.100"
