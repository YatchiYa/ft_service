#!/bin/sh

# Ensure docker and minikube are installed
if ! which docker >/dev/null 2>&1 ||
	! which virtualbox >/dev/null 2>&1 ||
    	! which minikube >/dev/null 2>&1
then
    echo Please install Docker and Minikube and virtualbox
    exit 1
fi

	export MINIKUBE_HOME="/sgoinfre/goinfre/Perso/yarab/ft_service/minikube/"


    # minikube apiserver setup
    minikube start --vm-driver=virtualbox \
        --cpus 2 --disk-size=30000mb --memory=3000mb \
		--extra-config=apiserver.service-node-port-range=1-31000

    # enable nginx controller
    minikube addons enable metrics-server
	minikube addons enable dashboard

	# to enable metallb 
	Kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml


	# set the ip
    export MINIKUBE_IP=$(minikube ip)
	
	sed -i ' ' "s/##MINIKUBEIP##/$MINIKUBE_IP/g" src/configMap.yml
	sleep 1
    eval $(minikube docker-env)
	sleep 1

    # build by local image
    docker build -t nginx-container src/nginx
	sleep 2
	
	# set the configMap
	Kubectl apply -f src/


	# just for test : to delete after

	# sed -i ' ' "s/$MINIKUBE_IP/##MINIKUBEIP##/g" src/confingMap.yml