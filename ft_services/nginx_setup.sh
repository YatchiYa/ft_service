cd ./srcs/nginx/srcs/
export WORDPRESS_IP=$(kubectl get services | grep wordpress | awk '{print $4}')
export PHPMYADMIN_IP=$(kubectl get services | grep phpmyadmin | awk '{print $4}')
export GRAFANA_IP=$(kubectl get services | grep grafana | awk '{print $4}')

sed "s/WORDPRESS_IP/$WORDPRESS_IP/g" ./index.html.bak > index.html.t1
sed "s/PHPMYADMIN_IP/$PHPMYADMIN_IP/g" ./index.html.t1 > ./index.html.t2
sed "s/GRAFANA_IP/$GRAFANA_IP/g" ./index.html.t2 > index.html
rm index.html.t1
rm index.html.t2
cd ../
docker build -t ft_nginx .
kubectl create -f ../yaml/nginx
cd ../../../
