
# export MINIKUBE_HOME=~/goinfre

export MINIKUBE_HOME=~/goinfre

echo "Minikube start ..."
minikube start --driver=virtualbox
minikube addons enable dashboard > /dev/null
minikube addons enable metrics-server > /dev/null
eval $(minikube docker-env)
echo "ftps..."
docker build -t ft_ftps ./srcs/ftps > /dev/null
echo "wordpress..."
docker build -t ft_wordpress ./srcs/wordpress > /dev/null
echo "mysql..."
docker build -t ft_mysql ./srcs/mysql > /dev/null
echo "phpmyadmin..."
docker build -t ft_phpmyadmin ./srcs/phpmyadmin > /dev/null
echo "grafana..."
docker build -t ft_grafana ./srcs/grafana > /dev/null
echo "influxdb..."
docker build -t ft_influxdb ./srcs/influxdb > /dev/null
echo "telegraf..."
docker build -t ft_telegraf ./srcs/telegraf > /dev/null

echo "apply differents configs..."
kubectl apply -f ./srcs/yaml/metallb/metallb_control.yaml > /dev/null
kubectl create -f ./srcs/yaml/metallb/metallb_config.yaml > /dev/null

echo "apply ftps..."
kubectl create -f ./srcs/yaml/ftps > /dev/null
echo "apply grafana..."
kubectl create -f ./srcs/yaml/grafana > /dev/null
echo "apply influxdb..."
kubectl create -f ./srcs/yaml/influxdb > /dev/null
echo "apply mysql..."
kubectl create -f ./srcs/yaml/mysql > /dev/null
echo "apply phpmyadmin..."
kubectl create -f ./srcs/yaml/phpmyadmin > /dev/null
echo "apply telegraf..."
kubectl create -f ./srcs/yaml/telegraf > /dev/null

echo "update wordpress configs"
sh wordpress_setup.sh
echo "apply wordpress..."
kubectl create -f ./srcs/yaml/wordpress > /dev/null

echo "update nginx configs"
sh nginx_setup.sh

export MINIKUBE_HOME=~/goinfre
minikube dashboard & > /dev/null
