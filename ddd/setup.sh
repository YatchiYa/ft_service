#! /bin/bash

# make clean -C ./srcs/nginx

# kubectl delete --all deployment
# kubectl delete --all services
# kubectl delete --all secret
# kubectl delete --all configmap
# kubectl delete --all pv,pvc
# kubectl delete --all pod
# minikube delete
# docker rmi $(docker images -q)
# docker rmi service-nginx service-wordpress service-mysql wordpress alpine yobasystems/alpine-mariadb


mount_container()
{
	echo "\033[1;32m->\033[0;32m Building $1 image ... \n"
	docker build -t service-$1 srcs/$1/ > /dev/null
	sleep 1
}

up_service()
{
	echo "\033[1;32m->\033[0;32m Up $1 service ... \n"
	kubectl apply -f srcs/$1/$1.yaml > /dev/null
	sleep 1
}

if ! minikube status >/dev/null 2>&1
then
    echo "\033[1;31m->\033[0;31m Minikube is not launched. Starting now... \n"
    if ! minikube start --cpus=2 --disk-size 11000 --vm-driver virtualbox --extra-config=apiserver.service-node-port-range=1-35000
	#if ! minikube start --vm-driver=virtualbox --cpus 3 --disk-size=30000mb --memory=3000mb --extra-config=apiserver.service-node-port-range=1-35000
    then
        echo "\033[1;31m->\033[0;31m Minikube can't be started! \n"
        exit 1
    fi
    
    minikube addons enable metrics-server
    minikube addons enable dashboard
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
    Kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
    # kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
fi

eval $(minikube docker-env)

names="nginx influxdb grafana mysql phpmyadmin wordpress telegraf ftps"

kubectl apply -f ./srcs/configmap.yaml
kubectl create configmap nginxconfigmap --from-file=./srcs/nginx/default.conf --from-file=./srcs/nginx/proxy.conf > /dev/null

for name in $names
do
	mount_container $name
    sleep 1
done

sleep 1

for name in $names
do
	up_service $name
    sleep 1
done

