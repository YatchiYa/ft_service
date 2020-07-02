# ft_services
<strong>#Clustering with Kubernetes</strong>


<strong>#Usage</strong> 
```sh
sh scripts/empty_space.sh & rm -r ~/Library/Caches/*
export MINIKUBE_HOME=/Users/hbrulin/goinfre
sh setup.sh 
WAIT FOREVER
```

- SSH: dans zsh
```sh
ssh admin@IP -p 6666
Login : admin. Pwd : admin.
```

- Wordpress wp-admin : admin, admin
	- En cas d'absence du fichier .htaccess et de pb permalinks : https://www.wpbeginner.com/beginners-guide/why-you-cant-find-htaccess-file-on-your-wordpress-site/

- PMA:
Login : wp_admin. Pwd : admin.

- FTPS: Login : user. Pwd : services
```sh
kubectl exec -ti FTPS_POD_ID sh
lftp
open -u user IP
set ssl:verify-certificate false
put /etc/ssl/private/pure-ftpd.pem
ls
get pure-ftpd.pem
!ls
```
- Grafana
	- admin, admin

- InfluxDb
	- DB name : telegraf
	- log : admin, password

- Crashtests
	- kill processes within container:
		- kubectl exec -it $(kubectl get pods | grep mysql | cut -d" " -f1) -- /bin/sh -c "ps"  
		- kubectl exec -it $(kubectl get pods | grep mysql | cut -d" " -f1) -- /bin/sh -c "kill number" : parfois a faire 2 fois
	- stop a container : not available in Kubernetes. Solution is to scale nb of replicas to 0.
		- kubectl scale --replicas=0 deployment/NAMEOFDEPLOY

- Verifier accessibilité d'un port:
	- telnet IP 21

<strong>#General Info</strong>

Les containers sont une méthode de virtualisation de système d’exploitation permettant de lancer une application et ses dépendances à travers un ensemble de processus isolés du reste du système. Cette méthode permet d’assurer le déploiement rapide et stable des applications dans n’importe quel environnement informatique.

Faire tourner des environnements linux isoles les uns des autres dans des containers tout en se partageant le meme noyau linux, le kernel.
Ne virtualise pas un nouvel OS comme une VM, plus leger, permet de faire tourner plus de conteneurs que de VM.

Comme un conteneur est relié au kernel, le conteneur n'a pas conscience de ce qui se passe en dehors de ce kernel et donc de la machine haute. C'est kubernetes qui va apporter l'orchestration et la gestion des conteneurs sur des clusters de serveurs.
Permet de prendre en charge plusieurs kernels et donc de pouvoir gerer les containers sur des differents serveurs hotes linux.

Orchestration :
- creer des services applicatifs sur plusieurs conteneurs
- planifier leur execution dans un cluster
- garantir leur integrite
- assurer leur monitoring

Pas besoin de s'occuper des couches infrastructures. On a à dispo directement l'environnement d'exécution, le conteneur, pour pouvoir y deployer le code. Kubernetes s'occupe des couches infrastructure sous-jacentes.
Docker package des appli dans des conteneurs. Mais :
- pas de persistence des donnees en cas d'arret du conteneur
- downtime si MaJ ou crash 
- pas de com entre conteneurs ou serveurs.
- pas de gestion des ressources selon RAM dispo. 
-> Pour une production stable, il faut un orchestrateur qui va utiliser au mieux les ressources d'un cluster. Il faut plusieurs serveurs, sinon ca ne sert à rien.

<strong>#Kubernetes Master :</strong> \
Serveur controlant les nodes.
<strong>#Nodes : </strong> \
Machines hebergeant les hotes docker qui exécutent les taches qui leur sont assignees. 
Au sein des nodes tournent des <strong>pods</strong> : environnement d'execution d'un ou plusieurs conteneurs docker.

Le master va dire quel node va faire tourner un pod, en se basant sur disponibilité des ressources.
information sur ressources : apportée par les <strong>Kubelet</strong>.
Si un noeud tombe, c'est le composant Kubelet qui va le signaler au master.
Le master gere aussi la resilience des pods. Repliques de pods dans plusieurs nodes - <strong>replica sets</strong>. Si un pod tombe, le master va executer le pod dans un autre node disponible. Plusieurs pods vont donc etre crees, chacun a une IP.

Dans les pods : des conteneurs. On deploie deux conteneurs sur un meme pod s'il est necessaire de partager les ressources locales. Tous les conteneurs d'un pod partagent les memes adresse IP, ports reseaux...

<strong>#Volume :</strong> \
Espace de stockage accessible a tous les conteneurs sur un pod. Repond à deux besoins :
- preserver les donnees au-dela du cycle de vie d'un conteneur, elles y sont stockees
- partager des donnees entre deux conteneurs d'un meme pod

<strong>#Service :</strong> \
Point d'entree permettant un acces a un groupe de conteneurs identiques -> c'est une VIP : virtual IP.
Kubernetes va fournir un service de routage en assignant une adresse IP et un nom de domaine à un service et va equilibrer la charge du trafic vers les differents pods. Les requetes de service sont alors transferees par kubernetes vers un des pods du service.
Un service recoit les requetes et les load balance vers les pods de toutes les apps, toutes les replicas.

<strong>#Globalement :</strong> \
Kubernetes execute au-dessus de l'OS et interagit avec les pods de conteneurs qui s'executent sur les noeuds. Le master recoit les commandes et relaie ces instructions au node.
Ce systeme de transfert fonctionne avec des services et le noeud le plus adapate pour la tache va etre choisi automatiquement. 
Le master va ensuite allouer les ressources aux pods designes dans le noeud pour qu'ils effectuent la tâche.
Lorsque le master planifie un pod dans un noeud, le kubelet de ce noeud ordonne a docker de lancer les conteneurs specifies, et c'est docker qui va demarrer ou arreter les conteneurs.
Le kubelet collecte le statut des conteneurs via docker et rassemble ces infos sur le serveur master.
=> avec K, les ordres proviennent d'un systeme auto, et plus d'un devops qui assigne manuellement des taches a chaque container.

<strong>#Deployment :</strong> \
To deploy applications : tell the master to start applications containers. The master schedules the containers to run on the cluster's nodes. The nodes communicate with the master using the Kubernetes API.
The Deployment instructs Kubernetes how to create and update instances of your application. Once you've created a Deployment, the Kubernetes master schedules mentioned application instances onto individual Nodes in the cluster.
Once the application instances are created, a Kubernetes Deployment Controller continuously monitors those instances. If the Node hosting an instance goes down or is deleted, the Deployment controller replaces the instance with an instance on another Node in the cluster. This provides a self-healing mechanism to address machine failure or maintenance.
-> Notamment pour mettre a jour applications dans un cluster, la maj sera faite automatiquement en mode running update. \
<strong>Pour pouvoir deployer sans avoir à push une img sur le docker hub, il faut eval $(minikube docker-env) -> comme ca ca sera run sur la VM. Il faut en outre config imagePullPolicy: Never dans le yaml.<\strong> Le cluster configure tout ce qui y est décrit.</strong>

<strong>#Installation:</strong>

- kubctl 
brew install kubernetes-cli
kubectl version

- minikube
Minikube is a lightweight Kubernetes implementation that creates a VM on your local machine and deploys a simple cluster containing only one node.
Minikube permet de travailler localement avec Kubernetes. cree une machine virtuelle. Il faut installer virtualbox pour l'utiliser.
Mnikube = 1 cluster. Au lancement de minikube, creation d'un cluster avec un node unique.
Minikube permet de tester en local, três léger, pas de vrais serveurs.

brew install minikube
export MINIKUBE_HOME=/Users/hbrulin/goinfre		//change home to goinfre
minikube config set vm-driver virtualbox		//indique quelle vm j'utilise
minikube start									//lance le cluster, config kubctl pour communiquer avec cluster

<strong>#CMDs :</strong>

- minikube delete 			- delete le cluster
- minikube stop				- stop cluster
- kubectl cluster-info
- minikube dashboard		- ouvre dashboard 
- kubectl browse //test
- kubectl get nodes
- kubectl get deployments
- kubectl get services
- kubectlget all -o wide	- voir tous les objets kubernetes
- kubectl create deployment NAME --image=path  	- il faut build l'img docker au prealable
- kubectl describe pods
- kubectl exec -ti img sh						- Start a bash session in container
- kubectl delete service/pod/deployment .... 	- si je delete un pod, normale;ent un nouveau se cree. Test à faire.
- kubectl logs service/pod/deployment ....
- kubectl get_deply nginx -o yaml > deploy.yaml  -output le yaml d'un deployment

<strong>#External visibility</strong> \
Pods that are running inside Kubernetes are running on a private, isolated network. By default they are visible from other pods and services within the same kubernetes cluster, but not outside that network. 
The kubectl command can create a proxy that will forward communications into the cluster-wide, private network. The proxy can be terminated by pressing control-C and won't show any output while its running.
```
kubectl proxy (sur un autre terminal)
```
We now have a connection between our host (the online terminal) and the Kubernetes cluster. The proxy enables direct access to the API from these terminals.

See APIs hosted through proxy endpoint :
```
curl http://localhost:8001/version
```

The API server will automatically create an endpoint for each pod, based on the pod name, that is also accessible through the proxy.

When you create a deployment, Kub creates a pod to hold your application instance. A Pod is a Kubernetes abstraction that represents a group of one or more application containers. Each Pod is tied to the Node where it is scheduled, and remains there until termination.
We need to get the Pod name, and we'll store in the environment variable POD_NAME.
```
export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo Name of the Pod: $POD_NAME
```

Then you can see the app : 
```
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/proxy/
```

#check that app up and running
```
curl localhost:8080
```

-> pas besoin de tout ca avec un yaml.

In order for the new deployment to be accessible without using the Proxy, a Service is required which will be explained in the next modules.
Use a service to <strong>expose</strong> an app outside a kubernetes cluster. A Service is defined using YAML.
The set of Pods targeted by a Service is usually determined by a LabelSelector. Although each Pod has a unique IP address, those IPs are not exposed outside the cluster without a Service. Services allow your applications to receive traffic. 
Several types of Services : 
- ClusterIP (default) - Exposes the Service on an internal IP in the cluster. This type makes the Service only reachable from within the cluster.
		-> ici j'expose le pod aux autres pods à l'intérieur du Cluster. Pas public.
- NodePort - Exposes the Service on the same port of each selected Node in the cluster using NAT. Makes a Service accessible from outside the cluster using <NodeIP>:<NodePort>. Superset of ClusterIP.
		-> Le champ NodePort dans le Yaml correspond au port accessible par l'exterieur. Tjrs entre 30000 et 32767. C'est celui qu'on va utiliser apres localhost.
		-> Le Target_port est lui celui qui est accessible en interne par les autres pods (ex: 8080).
		-> le Port est le port d'ecoute.
- LoadBalancer - Creates an external load balancer in the current cloud (if supported) and assigns a fixed, external IP to the Service. Superset of NodePort. 
		->attribue IP directement aux deploiements. 
		-> Via Controller Ingress : Permet d'entrer avec l'IP machine et de rediriger les flux vers le bon pod. Controller Ingress permet d'entrer sur le réseau interne à Kubernetes.
- ExternalName - Exposes the Service using an arbitrary name (specified by externalName in the spec) by returning a CNAME record with the name. No proxy is used. This type requires v1.7 or higher of kube-dns.

A Service routes traffic across a set of Pods. Services are the abstraction that allow pods to die and replicate in Kubernetes without impacting your application. Discovery and routing among dependent Pods (such as the frontend and backend components in an application) is handled by Kubernetes Services.

To create a new service and expose it to external traffic we’ll use the expose command with NodePort as parameter : 
```
kubectl expose deployment/NAME_DEPLOYMENT --type="NodePort" --port 8080
```

To find out what port was opened externally (by the NodePort option) we’ll run the describe service command:
```
kubectl describe services/NAME_SERVICE
```

Create an environment variable called NODE_PORT that has the value of the Node port assigned:
```
export NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
echo NODE_PORT=$NODE_PORT
```

Now we can test that the app is exposed outside of the cluster using curl, the IP of the Node and the externally exposed port:
```
curl $(minikube ip):$NODE_PORT
```

<strong>#Running muliple instances of the app</strong> \
The Deployment creates only one Pod for running our application. When traffic increases, we will need to scale the application to keep up with user demand.
Scaling is accomplished by changing the number of replicas in a Deployment. You can program scaling hourly.
Scaling out a Deployment will ensure new Pods are created and scheduled to Nodes with available resources. Scaling will increase the number of Pods to the new desired state.
Running multiple instances of an application will require a way to distribute the traffic to all of them. Services have an integrated load-balancer that will distribute network traffic to all Pods of an exposed Deployment. Services will monitor continuously the running Pods using endpoints, to ensure the traffic is sent only to available Pods.
Once you have multiple instances of an Application running, you would be able to do Rolling updates without downtime.

<strong>#Methode descriptive vs. Methode imperative</strong> \
Avec Kubernetes, on décrit l'état final de ce qu'on souhaite. On stocke l'etat désiré dans la BD du master, ETCD. Le master va interroger les différents nodes et vérifier leur conformité à l'état désiré.
La commande get affiche un champ desired : c'est le nb 'instance, replica sets qu'on a demandé de déployer.
On va décrire l'état désiré grâce aux fichiers en format YAML.

La methode imperative : on installe tout -> apt get-install. 
Est-ce que cela veut dire que pqs besoin de telecharger les paquets dans les Dockerfile de chaque conteneur??

<strong>#YAML</strong> \
Si on apply -f un fichier yaml, les instances qui y sont decrites sont run par kubernetes -> les deploiements sont lances, les services exposes etc... \
Le cluster configure tout ce qui y est décrit.

Champ kind : c'est la qu'on definit ce qu'on configure : service, deployment, scaling de pods...
Champ image d'un deploy : img docker.

On separe les differentes instances qu'on deécrit par '---'.

<strong>#Volumes & persistent volumes</strong> \
Persistent volumes : Ne dependent pas du pod ou conteneur si celui-ci crash.
Persistent volume claim : declare size needed. Permet d'utiliser meme template apres sur differents pods, pour que kubernetes mount le volume sur chaque pod.
https://www.youtube.com/watch?v=inJ7YJ-jt8I

<strong>#FTPS</strong> \
File Transfer Protocol Secure. Protocole d'échange informatique de fichiers sur réseau TCP/IP.
FTP sécuriś avec SSL ou TLS.
Permet au visiteur de vérifier l'identité du serveur auquel il accède grâce à un certificat d'authentificaton + communication chiffrée.

Si la connection s'effectue sur le port 21, alors on est sur du FTP avec chiffrement explicite (sinon chiffrement implicite, port 990).
En chiffrement explicite:
- TLS : commande AUTH LSC demande au serveur de chiffrer le transfert de commande en TLS, et PROT P demande le chiffrement du transfert de données en TLS.
- SSL : AUTH SSL pour transfert de commande et de données via SSL.

FTP et HTTP sont tous deux hautement considérés comme les protocoles de transfert de fichiers les plus souvent utilisés pour transférer des données entre un client et un serveur. HTTP fonctionne de la même manière avec les fonctions communes entre FTP et SMTP. Cependant, ils ont aussi établi des différences.

FTP
- Transférer des fichiers d'un hôte à un autre.
- Il établit deux connexions, l'une pour les données et l'autre pour la connexion de contrôle.
- FTP apparaîtra dans l'URL.
- Efficace pour le transfert de fichiers volumineux.
- Cela nécessite un mot de passe.
- Les fichiers qui seront transférés vers l'hôte par FTP seront enregistrés dans la mémoire de l'appareil hôte.
HTTP
- Ceci est utilisé pour accéder à des sites Web.
- Seule la connexion de données est établie.
- HTTP apparaîtra dans l'URL.
- Efficace pour le transfert de petits fichiers comme pour les pages Web.
- Il ne nécessite aucune forme d'authentification.
- Le contenu qui sera transféré vers un périphérique via HTTP sera enregistré dans la mémoire du périphérique.

Utiliser lftp dans la console du container ftps. - apk add lftp - client ftp qui va faire requete serveur
http://momh.fr/tutos/Linux/lftp 
open -u user ftps-svc 

https://www.howtoforge.com/how-to-configure-pureftpd-to-accept-tls-sessions-on-debian-lenny 

<strong>#Grafana</strong> \
Logiciel qui permet la virtualisation et la mise en forme de données métriques. Permet de réaliser dahsboard et graphiques depuis pls sources, dont des bases de données dites "time series databases" comme Influxdb.

Time series databases : db ordonnee selon des points dans le temps. Usually sequence taken at successive equally spaced points in time.

<strong>#Kubernetes Dashboard</strong> \
https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md 
https://www.replex.io/blog/how-to-install-access-and-add-heapster-metrics-to-the-kubernetes-dashboard
kubectl delete clusterrolebinding kubernetes-dashboard : necessary prior to applying yaml file for dashboard
https://kubernetes.io/fr/docs/tasks/access-application-cluster/web-ui-dashboard/

<strong>#influxdb & kubernetes secrets</strong> \ 
Kubernetes secrets are a way to store sensitive information (such as passwords) and inject them into running containers as either environment variables or mounted volumes. This is perfect for storing database credentials and connection information, both to configure InfluxDB and to tell Grafana how to connect to it.

https://opensource.com/article/19/2/deploy-influxdb-grafana-kubernetes
https://kubernetes.io/fr/docs/concepts/configuration/secret/

Tuto : https://blog.ouvrard.it/2015/11/24/influxdb-grafana/

<strong>#eval minikube docker env</strong> \
The command minikube docker-env returns a set of Bash environment variable exports 
to configure your local environment to re-use the Docker daemon inside the Minikube instance.
Passing this output through eval causes bash to evaluate these exports and put them into effect.
You can review the specific commands which will be executed in your shell by omitting 
the evaluation step and running minikube docker-env directly. However, this 
will not perform the configuration – the output needs to be evaluated for that.

<strong>#nginx configuration file</strong>
Liste parametres : http://nginx.org/en/docs/ngx_core_module.html#worker_connections 
http, server, events, location, s'appellent un contexte.

- <strong>worker_processes	auto</strong> : it will be determined automatically by the number of core
- <strong>worker_connections	1024</strong> : Sets the maximum number of simultaneous connections that can be opened by a worker process.
- MIME = Multipurpose Internet Mail Extensions. It is a standard that indicates the nature and format of a document, file, or assortment of bytes. All web browsers use the MIME type to determine how to process a URL. Hence, it is essential that Nginx send the correct MIME type in the response’s Content-Type header.
- <strong>include        /etc/nginx/mime.types;</strong> : Maps file name extensions to MIME types of responses. 
- <strong>default_type       application/octet-stream;</strong> : make a particular location emit the “application/octet-stream” MIME type for all requests. A MIME attachment with the content type "application/octet-stream" is a binary file. Typically, it will be an application or a document that must be opened in an application, such as a spreadsheet or word processor.
- <strong>sendfile      on;</strong> : permet de forcer l’utilisation de l’appel système sendfile pour tout ce qui concerne l’envoi de fichiers. sendfile permet de transférer des données d’un descripteur de fichier vers un autre directement dans l’espace noyau. Se substitue à l’utilisation combinée de read et write. Si vous servez des fichiers statiques stockés localement, sendfile est indispensable pour améliorer les performances de votre serveur Web.
	https://thoughts.t37.net/optimisations-nginx-bien-comprendre-sendfile-tcp-nodelay-et-tcp-nopush-2ab3f33432ca
- <strong>keepalive_timeout           3000;</strong> :  indicating the minimum amount of time an idle connection has to be kept opened (in seconds)
- <strong>gzip on;</strong> : helps to reduce the size of transmitted data by half or even more. http://nginx.org/en/docs/http/ngx_http_gzip_module.html


<strong>#Copy to and from pods</strong>
https://medium.com/@nnilesh7756/copy-directories-and-files-to-and-from-kubernetes-container-pod-19612fa74660


<strong>#SSH</strong>
https://www.youtube.com/watch?v=Kp9hIsIK38I

<strong>#Ressources</strong>
- Installation :
	- https://kubernetes.io/fr/docs/tasks/tools/install-minikube/ 
	- https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/
	- https://minikube.sigs.k8s.io/docs/reference/environment_variables/ 
- Minikube : https://kubernetes.io/fr/docs/setup/learning-environment/minikube/
	- https://www.ionos.fr/digitalguide/serveur/configuration/tutoriel-kubernetes/ 
	- https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-intro/ 
	- https://kubernetes.io/docs/tutorials/hello-minikube/ 
- https://time-to-first-byte.info/tutoriel-kubernetes-une-introduction-aux-bases/ 
- https://www.youtube.com/watch?v=37VLg7mlHu8&list=PLn6POgpklwWqfzaosSgX2XEKpse5VY2v5&index=1
- https://www.youtube.com/watch?v=b5vJsYR-Vbo&t=4087s
- videos kubernetes : http://bit.ly/2WN9Ojj
- tuto WP et PMA : 
	- https://howto.wared.fr/installation-wordpress-ubuntu-nginx/ 
	- https://www.itzgeek.com/how-tos/linux/debian/how-to-install-phpmyadmin-with-nginx-on-debian-10.html

# ft_services
