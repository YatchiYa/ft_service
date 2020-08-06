## 출처: https://github.com/simian114/ft_services
- 엔진엑스yaml중 livenessprove줄 정렬해줘야 오류 안남
- plain http 가 https포트로 왔다는 오류생기면 nginx.conf에 error_page 497 https://$host$request_uri적용해볼것
- include에도 snippets앞에 /etc/nginx를추가해볼것
# 내가 이해한 내용..큰그림에서
- 미니쿠베? 요걸 가지고 클러스터 환경을 마련해줌. 실제 배포를 위해선 구글의 gcloud, 아마존의 AWS등의 클라우드클러스터를 사용하는거 같음! 명령어 `minikube start --driver=virtualbox`로 클러스터 환경 세팅하고, 그 클러스터 환경위에 minikube라는 노드가 하나 생기게 됨. 이 노드안에 서비스들이 배포됨.
- 대시보드로 노드 속 오브젝트들의 상태를 시각적으로 관찰하고 관리할 수 있음 -> 명령어 `minikube dashboard`
- 대시보드에 CPU와 메모리 사용량에 대한 정보를 얻어오려면 metrics-server애드온을 사용허가해야함 -> 명령어 `minikube addons enable metrics-server`
- 도커 빌드로 준비한 도커파일들을 이미지화시키기 전에, 우리는 자동화를 위해 실행스크립트를 쓰는데 쉘스크립트의 도커 빌드 명령어가 제대로 먹히려면 내 쉘과 미니쿠베의 도커데몬을 연결시켜야 되나봐. 그래서 해주는 명령어가 `eval $(minikube docker-env)` 인가봐!
- 만들어둔 도커 이미지들을 빌드해줄거야. 이미지는 알파인리눅스, (FROM alpine)에서 ftps, wordpress, mysql, phpmyadmin, grafana, influxdb, telegraf를 설치하고, 로컬에 만들어둔 설정파일들이 컨테이너환경에 적용될수 있게 설정파일들과 그 설정파일들을 사용하는 스크립트파일을 COPY해주는 등 초기화 과정을 거쳐서 이미지를 만들게 될거야. 마지막에 컨테이너 빌드시 컨테이너에서 실행할 명령어로 COPY로 넘겨준 실행 스크립트를 실행하도록 해주면 이미지는 마무리됨. 
- 즉, 이미지 프레임워크는, [FROM alpine -> apk-add 필요한거 다운 -> COPY 설정파일, 설정파일 적용할 실행스크립트 -> CMD 스크립트 실행 명령]
- 이렇게 만들어준 이미지는 오브젝트 생성을 위한 각각의 .yaml을 create 혹은 apply할때 spec.template부분에서 쓰이게 될거야! 템플릿은 파드를 만들때(새롭게 만들때 혹은 오류발생한 파드를 죽이고 새 파드를 만들때) 어떤 이미지를 사용할지, 그 템플릿을 설정하게 되는데, 위에서 빌드한 이미지들이 이때 사용이 되는것임!

# 자세히 다뤄보자
<br>도커이미지로 클러스터를 구성할수있고
<br>yaml파일로 클러스터를 설계할수있다
<br>설계가 먼저일까, 구성요소를 만드는게 먼저일까.
<br>설계를 먼저해보자.
## 설계
쿠버네티스에 대한 정보를 찾아보다보면 pod라는걸 굉장히 많이 봤을것이다. 하나의 파드내에 여러 애플리케이션을 담은 컨테이너가 있을수있고 그 컨테이너들이 서로 정보를 주고받으며 우리가 원하는 작업을 하게될것이다. 이런 파드를 클러스터 외부에 있는 사용자가 접근하려면 외부 엔드포인트가 필요하고 그걸 해주는게 서비스객체(로드밸런싱)다. 어떻게 파드를 구성할지, 어떻게 서비스를 구성할지를 yaml파일에서 설정하게 되는데, kind가 pod인 yaml파일을 작성하고 이대로 파드들을 서비스하게되면, 파드객체가 죽었을때 재시작하지 못하고 서비스객체도 죽어버린다. 즉, 파드가 잘 살아서 돌고있나를 계속 감시하다가 파드가 죽으면 다시 하나 새롭게 만들어주는 파드의 관리자가 필요한것이다. 이걸해주는게 deployment객체다. deployment는 파드가 죽으면 새롭게 생성해줘야하기때문에 파드가 어떤 스펙인지 알고있어야하고 몇개의 파드를 관리할지에대한 정보를 알고있어야한다. 이를 yaml파일에 적어주게되면 결국 감시대상이 된 pod는 deployment에 의해 생성되고 관리되어지며 service 에 의해 외부로 노출되어 외부 사용자가 파드의 기능을 사용할수있게 될 것이다. 무슨일이 생겨도 기능은 계속 유지되길 원하기 때문에 우리는 이런식으로 yaml파일을 설계할것이다. (deployment로 원하는 파드를 생성, 관리하고, service로 외부 포트를 컨테이너의 포트와 연결해주는식)

### 외부에있는 사용자와 파드를 이어주는 서비스의 로드밸런싱은 Metallb를 사용한다.
쿠버네티스에서의 서비스란, 임의의 사용자가 쿠버네티스 클러스터내의 파드에 접근할수 있게끔 고정된 주소나 외부IP를 생성해주는 하나의 자원이라고 할수있다. 파드의 경우 발급되는 IP가 랜덤하고, 리스타트할때마다 또 바뀌기 때문에 고정된 엔드포인트로 호출하기 어렵다. 그리고 여러 파드에 같은 애플리케이션을 운용할경우 이 파드간의 로드밸런싱을 지원해줘야하는데, 이런 역할을 서비스가 해준다. 서비스는 지정된 IP로 생성이 가능하고 여러 파드를 묶어(파드의 이름으로 지정함) 로드 밸런싱이 가능하며 고유 DNS이름을 가질수있다. 서비스는 IP주소 할당 방식과 연동 서비스에 따라 4가지로 구별할수있다.
- Cluster IP: 서비스에 대한 디폴트 설정으로, 서비스에 클러스터의 내부IP를 할당한다. 클러스터 내에선 이 서비스에 대해 접근할수있지만 클러스터 외부엔 외부IP를 할당 받지 못했기때문에 접근이 불가능하다. 그냥 디플로이해버리면 외부IP가 pending으로만 나타나는게 이거때문. 
- LoadBalancer: 클라우드 벤더(제 3자)에서 제공하는 서비스 설정 방식으로, 외부 IP를 가지고있는 로드밸런서를 할당해준다. 외부 IP를 가지고 있기 때문에 클러스터 외부에서 접근이 가능하다. 이게 우리 과제에서 채택하는 방식이고 여기서 말한 클라우드 벤더란 Metallb가 된다.
- Node IP: 클러스터 IP로만 접근가능한게 아니라 모든 노드의 IP와 포트를 통해서도 접근가능하게된다.
- External name: 외부서비스를 클러스터 내부에서 호출하고자할때 사용한다. 

우리는 MetalLB가 지원해주는 로드밸런싱설정을 사용할거다.
### MetalLB가 제공하는 로드밸런싱 적용법
[참고: https://medium.com/@shoaib_masood/metallb-network-loadbalancer-minikube-335d846dfdbe]

```
Kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
```

- yaml파일을 적용한뒤 나중에 Service객체 Type을 LoadBalancer로 해주면 메탈엘비의 설정이 적용되어 외부엔드포인트를 가질수있게된다!
- 단, 추가 설정을 해줘야 하며 가장 추천하는건 layer 2 configuration이다. 준비된 프레임워크파일에서 한개만 건들여주면 되는데 바로, `minikube start --driver=virtualbox`로 미니큐베시작한뒤 `minikube ip`를 치면 나오는 ip값을 넣어주는것이다.
```
apiVersion: v1
kind: ConfigMap
metadata:
 namespace: metallb-system
 name: config
data:
 config: |
  address-pools:
  - name: default
    protocol: layer2
    addresses:
    - [minikube ip 값](대괄호 제외해서..)
```
두개의 yaml파일이면 서비스의 로드밸런싱관한 설정은 끝낼수있다. kind: Service 의 spec.type: LoadBalancer로 지정해주면 이제 서비스에대한 외부 엔드포인트 겟할수있음.  

### ftps 설계하기 /(왜?)ftps는 파일전송 프로토콜인데 로드밸런서로 서비스가 지정될 필요가 있나? 21포트를 리슨해야해서?? 그리고 호스트포트는 왜 컨테이너포트와 일치시킨걸까?
ftps는 파일전송 프로토콜임. ftp 에 ssl인증서를 적용한거라고 보면됨.
- Deployment
> kind: Deployment
metadata는 디플로이먼트의 이름과 라벨을 지정할수있다.
spec.selector는 컨트롤할 파드를 라벨로 지정할수있다.
spec.template는 파드에 대한 메타데이터, 스펙에대한 정보를 적어준다.
메타데이터엔 파드의 라벨을, 스펙엔 어떤 컨테이너의 이름과 어떤 이미지를 실행할지, 포트정책과 livenessProbe등에 대한 설정을 한다.

- Service
> kind: Service
spec.selector로 서비스할 파드를 선택한다. type은 LoadBalancer로 지정해서 적용할 metallb의 로드밸런싱정책을 통해 외부주소로 노출될수있도록 해준다.
port -> 미니큐브와 서비스객체연결, targetPort -> 파드와 서비스객체 연결

### mysql - phpmyadmin, mysql - wordpress설계하기
- mysql같은경우 데이터베이스로 역할하며 파드가 죽더라도 정보는 계속 살아있어야한다. 또한 데이터베이스가 phpmyadmin과 wordpress에 붙어서 연동되어야한다. 데이터의 유지를 위해 kind: PersistentVolumeClaim을 제작하고 이를 kind: deployment 에서 파드가 생성될때 컨테이너의 /var/lib/mysql에 해당 볼륨이 마운트될수있도록 지정해준다. mysql은 외부로 노출될 필요가 없기 때문에 Service는 type: ClusterIP로 지정해주고, phpmyadmin, wordpress와 연결될수있는 포트로 3306포트(mysql의 기본 포트)를 열어주도록 한다. 여기서 서비스의 metadata이름이 곧 워드프레스의 wp-config.php에서 DB_HOST가 되어 워드프레스와 연결된다. 
- phpmyadmin의 경우 외부로 노출될 기능이기 때문에 로드밸런서로 서비스타입을 지정해주고, 연동할 서버를 지정해주는 config.inc.php파일의 내용을 조작해 mysql과 연동될수있도록 해준다. 이런 설정파일같은 경우, 로컬에서 작성해서 이미지 빌드시 옮겨주는 방법도 있지만, 컨테이너와 분리해서 관리할수있게 해주는 방법도 존재한다. 이걸 kind: ConfigMap으로 지정해줘서 해당 설정내용을 담은 파일을 deployment시 볼륨설정(ConfigMap의 이름지정)-컨테이너의경로에 마운트 해서 사용하면된다.
- wordpress의경우 외부로 노출될 기능이기 때문에 로드밸런서로 서비스타입을 지정해준다. 연동과 관해선 로컬의 my.cnf와 wp-config.php를 만들어 mysql컨테이너상 데이터 저장 경로와 DB_HOST이름을 지정해주고 이미지파일 빌드시 넘겨줄수있도록 설정해준다

### influxdb - telegraf - grafana
influxdb는 시계열데이터를 효율적으로 저장하고 관리하는 프로그램, telegraf는 데이터를 수집해서 데이터베이스로 정보를 보내준느 프로그램, grafana는 데이터를 시각화하고 대시보드로 관리하기 용이하게 만들어주는 프로그램이다. influxdb-telegraf-grafana순으로 설계해보자
- influxdb 역시 데이터베이스역할이므로 PersistentVolumeClaim후 deployment로 파드생성시 파드의 컨테이너내부 경로에 볼륨이 마운트될수있도록 설정해준다. influxdb의 경우, 초기화설정관련해서 influxdb.conf라는 파일에 설정에 대한 정보를 담고 이를 토대로 데이터베이스를 초기화한다. 이런 설정파일을 컨테이너 내부와 분리해내서 ConfigMap형태로 yaml파일로 보관할수있고 deployment시 볼륨마운트로 설정파일을 덮어줄수있다. 어디로부터 데이터를 받아올지와 계정관련한 보안사항을 kind: Secret형태의 yaml파일로 보관할수있는데 여기서 stringData: 밑에 키:밸류형태로 값을 저장해둘수있다. 우리는 influxdb를 telegraf로부터 받아올것이기 때문에 telegraf기능을하는 파드의 서비스명을 INFLUXDB_DB: telegraf로 설정해준다. 
- telegraf의 경우 우리가 사용하는 docker로 부터 발생되는 정보를 읽어서 influxdb에 쏴줘야한다. telegraf는 관련 설정을 telegraf.conf라는 파일로 설정해두는데 역시 이를 ConfigMap형태로 yaml파일에 담아서 볼륨마운트해줄수있다. 데이터를 쏴주는걸 OUTPUT PLUGINS에서 지정해주고있고 받아오는걸 INPUT PLUGINS에서 지정하고있다. 마찬가지로 kind: Secret형태의 yaml파일을 만들어 ConfigMap에 쓰이는 값을 좀더 안전하게 지정해줄수있다. 도커로 부터 읽어오는건 docker-unix-socket을 통해 읽어올수있고 해당내용은 deployment.yaml에서 volume설정할때 볼륨의 이름을 docker-unix-socket으로 지정해주고 경로를 /var/run/docker.sock, 타입을 소켓으로 지정해주면 쓸수있다.
- 그라파나는 외부로 노출될 기능이기때문에 서비스시 loadbalancer로 지정한다. 설정에 관한 정보는 grafana.ini라는 파일로 관리하는데 이를 ConfigMap형태로 작성해서 관리할수있다. 데이터 연동관해선 datasource.yaml로 읽어올 데이터베이스의 url을 설정해서 연동할수있고, 또 그라파나의 기능중 하나인 대시보드에 대한 설정을 dashboard.yaml에서 할수있다. 해당 파일들을 프로그램설치시 생성되는 sample.ini와 provisioning디렉토리에 존재한다. deployment에서 설정파일을 볼륨화하여 컨테이너의 경로에 마운트해주고 envFrom으로 secret객체를 넘겨주면 끝.

## 도커 이미지만들기
### ftps
![](https://github.com/sebaek42/sebaek42/blob/master/img/ft_services/ftps.jpg?raw=true)
<p>ftps는 파일전송 프로토콜임. ftp 에 ssl인증서를 적용한거라고 보면됨. 21포트를 리슨하라고 하지만, ftps의 경우 클라이언트의 요청을 받는 포트, 데이터를 보내주는 포트가 따로 있다. 액티브모드 패시브모드에 따라 데이터를 보내주는 포트가 달라지는데 따라서 도커파일에서 EXPOSE 20 21 21100-21102를 해줌! 또 우린 openssl로 개인 인증서를 발급받아 사용할거고 알파인리눅스환경에서 주로 사용하는, 아주 보안 좋은 very secure ftp, vsftpd를 사용할거라서 openssl과 vsftpd를 설치해줄거임!</p>
<p>openssl 커맨드로 인증키를 만들때 -conf 옵션을 쓸수있음. openssl 커맨드 사용시 여러가지 옵션값을 넣어줘야하는데, 이를 미리 설정해둔 파일을 만들어서 해당 파일을 openssl커맨드에 넣어줄수 있게됨. 그 설정 파일의 이름은 openssl.conf이고,

```
[req]
prompt                 		= no # no로 해야지만 물어보는 과정 생략함.
default_bits       			= 4096
default_md             		= sha384 # 암호화 알고리즘
distinguished_name 			= req_distinguished_name # 아래 섹션 참고
[req_distinguished_name]
countryName         		= AU
organizationName    		= localhost
commonName          		= localhost
```
이렇게 생겼음. 로컬에서 미리 만들어두고 나중에 도커파일에서 이걸 컨테이너의 /etc/ssl/private/에 넣어주면 openssl 커맨드 쓸때 저 경로대로 설정 파일 넘겨줄수있음!
</p>
<p>
  vsftpd를 사용한다그랬징, vsftpd는 very secure file transfer protocol daemon이다. 서버는 inetd, xinetd같은 슈퍼서버에 의해 런치될수있는데, 다른 방법으로 vsftpd 나홀로 서버를 런칭하려면 vsftpd.conf파일을 좀 수정해줘야 한다. 일단, 컨테이너에서 vsftpd를 설치하면 /etc/vsftpd/경로에 vsftpd.conf 파일이 생성되는데 그 파일의 옵션을 좀 수정해 준뒤 파일을 내 로컬로 가져와서 이미지 빌드시 COPY 해줄수 있도록 한다. 중요한 옵션으로는...listen=YES로 해줘야 vsftpd자체로 실행될수 있게된다.
</p>
<p>openssl명령어 실행시 사용될 openssl.conf, vsftpd 명령어 실행시 사용될 vsftpd.conf설정파일들을 만들었으니 이제 이미지가 실행될때 컨테이너 내부에서 실행될 컨테이너 초기화 스크립트를 만들어야한다. 도커파일에선 CMD ["/run.sh"]로 실행될 수 있도록 카피도 해주는거 잊지말아야함.
  실행스크립트(run.sh)에서 이제 인증키로 ftps사용할 user와 패스워드, user의 HOME을 설정해준다.
  `mkdir -p /ftps/sebaek` `adduser --home=/ftps/sebaek -D sebaek`
  > -D를 해줘야 디폴트로 지정되는 사태를 막을수있음(디폴트로 지정되는경우 LOGIN네임이 BASE_DIR이 되고 BASE_DIR를 로그인 디렉토리로 사용함. 메뉴얼에 나와있는말인데 먼소리지..;;). 우린 HOME_DIR을 ftps/sebaek으로 지정하고싶음.(왜?)
  그리고 뒤의 sebaek이 user에 더해지게됨.

  이제 생성한 user인 sebaek에 비밀번호를 설정해줌.
  > `echo "sebaek:sebaek" | chpasswd` 이렇게 유저 sebaek의 비밀번호를 sebaek으로 설정해주고 etc/vsftpd/vsftpd.userlist에도 sebaek을 추가해준다. `echo "sebaek" >> etc/vsftpd/vsftpd.userlist` 이렇게.

  추가로, FTP서버에서 발생하는 모든 이벤트의 실시간 로그를 보려면 tail -f vsftpd.log를 사용하는데 파일이 존재하지 않기때문에 로그가 데이터를 채우지 않는경우가 존재한다. 따라서 이 로그를 담아줄 파일 vsftpd.log를 생성해야하며, 보편적으로 이 로그파일의 위치는 /var/log/vsftpd.log이다. 우리도 로그를 보고싶기때문에 `touch /var/log/vsftpd.log`를 스크립트에 적어주도록하자.
  추가로, FTP서버에서 발생하는 모든 이벤트의 실시간 로그를 보려면 tail -f vsftpd.log를 사용하는데 파일이 존재하지 않기때문에 로그가 데이터를 채우지 않는경우가 존재한다. 따라서 이 로그를 담아줄 파일 vsftpd.log를 생성해야하며, 보편적으로 이 로그파일의 위치는 /var/log/vsftpd.log이다. 우리도 로그를 보고싶기때문에 `touch /var/log/vsftpd.log`를 스크립트에 적어주도록하자.
  마지막으로, 대망의 openssl req명령으로 인증키를 받아보자. 우린 self signed root certificate를 받을거니까 [openssl req -x509 -newkey rsa:2048 -keyout key.pem -out req.pem] 형식의 명령어를 사용하자, 단 암호화하진 않을것이기 때문에 -nodes옵션도 추가해준다.(왜?) `openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem -config etc/ssl/private/openssl.conf`완성. 무슨 의민지 뜯어보면, vsftpd.pem 이름의 프라이빗키를 만들고 -out 옵션으로 vsftpd.pem키의 certificate request를 보내달라, 이때 키를 생성할때, 설정값이 담긴 openssl.conf를 -config옵션을 사용해서 인자로 넣어주고 이를 반영해서 키를 만들어달라..가 되겠다(맞나?). /etc/ssl/private/경로는 이 명령어를 실행하기 전에 mkdir -p /etc/ssl/private를 해줌으로서 미리 공간을 만들어주고 개인키를 보관하는 용도로 두면 된다.
</p>
<p>
  vsftpd.pem키가생성되고 인증되고나면 vsftpd커맨드로 ftps서버를 실행시킬수있다! 이로써 클라이언트의 요청을 받아 파일을 안전하게 보내줄수있는 ftps서버가 생성되었다. 개인키의 사용자는 sebaek, 비밀번호도 sebaek이다.
  `/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf` 로 실행하면 ftps서버는 마무리!
</p>

- 파일전송
```
curl ftp://EXTERNAL-IP:21 --ssl -k --user sanam -T filename
  enter password : 123456789
  // --ssl : ftps 쓰기 위함
  // -k : 인증 문제 무시
```
- 파일다운로드
```
curl -u sanam:123456789 'ftp://EXTERNAL-IP:21/toDOWNLOAD' --ssl -k -o ./DOWNLOADED
```
- 파일전송확인
```
kubectl get pods // ftp 파드 이름 확인
  kubectl exec -it [POD_NAME] -- sh // ftps 컨테이너 접속
  cd ftps/sanam // 전송된 파일 저장되는 곳
```

### docker build -t ft_mysql ./srcs/mysql
<p>mysql은 관계형 데이터베이스 '관리' 시스템이다. root계정으로 로그인해주고(명령어는 mysql -uroot) create database 명령으로 데이터베이스를 만들수있다. 근데 실질적으로 데이터가 보관되는 장소는 테이블이다. 따라서 워드프레스의 데이터를 받아올 wordpress이름의 데이터베이스를 만들기 전에 테이블을 만들기위한 밑작업(?)이 필요하다.</p>
- mysql 설치
- /run/mysqld 디렉토리 생성 (왜?)
- my.cnf 파일 복사 -> 유닉스/리눅스 시스템상 MySQL의 옵션파일(설정관련옵션)
> mysql의 초기설정을 담는 파일임. mysql의 유저명, 포트, 데이터 저장위치, 바이너리 로그경로, 외부와 연결하기위한 통로, 외부컨테이너와 연결 허용여부등을 담음.

- mysql-init 파일 복사 -> mysqld 로그인후 사용할 초기화관련 명령어들 모음
> FLUSH PRIVILEGES;
CREATE DATABASE wordpress;
GRANT ALL PRIVILIEGES ON *.* TO 'admin'@'%' IDENTIFIED BY 'sebaek' WITH GRANT OPTION;
FLUSH PRIVILEGES;
- run.sh파일 복사
> 열심히 만들어서 컨테이너에 복사해준 설정파일과 스크립트를 사용할 차례임.
`mysql_install_db --user=root` 명령을 통해 mysql server에 대한 초기 세팅을 해줌. 이때 유저가 루트인 이유는 알파인 컨테이너에서 다른 사용자를 추가하지 않았기 때문!
`mysqld --user=root --bootstrap < /tmp/mysql-init` 일단, mysqld --user=root 까지만 입력하면 mysql서버가 시작된다. 그런데 --bootstrap옵션을 넣어줌으로서 서버가 시작되기전에 몇가지 밑작업을 수행할 수 있게된다. 위 명령을 분석해보면, mysql을 root로 실행하되, --bootstrap 옵션을 줘서 먼저 '데이터 테이블(data dictionary)'을 만들고, 데이터베이스 명령어가 적힌 mysql-init파일의 텍스트를 넘겨줘서 wordpress 이름의 데이터베이스를 만들고 권한설정을 마무리해준다. 즉 --bootstrap은 데이터 테이블을 만들어주고, mysql-init은 wordpress이름의 데이터베이스를 만들어주는 역할을 각각한다고 보면 될것같다. 해당 명령어 다음
`mysqld --user=root` 명령으로 이제 진짜로 서버를 시작시킨다.
### docker build -t ft_wordpress ./srcs/wordpress
설치관련: php7 패키지 설치, mysql-client설치, 워드프레스 소스다운
Copy관련: wp-config.php, wordpress.sql
> wp-config.php : mysql과 연동하기 위해 필요한 데이터베이스명, 데이터베이스유저, 패스워드, 데이터베이스호스트, 워드프레스의홈주소, 워드프레스사이트URI관련정보가 담김. 그런데 워드프레스의 주소관련 정보는 실행할때마다 달라지기 때문에 서비스가 시작되고나야 그 정보를 얻어와 연동할수있음
wordpress.sql : 워드프레스사용자정보, 데이터작성법등이 담긴 sql문 파일. 이걸 mysql서버에 쏴주는걸로 워드프레스의 데이터가 서버에 알맞은 테이블에 알맞게 저장됨. 
실행흐름: setup.sh -> docker build -t ft_wordpress -> kubectl create -f ./srcs/yaml/wordpress -> /tmp/run.sh실행으로 wordpress서비스 시작 -> wordpress_setup.sh -> kubectl exec $WORDPRESS_POD -- sh /tmp/init-wordpress.sh -> mysql과 wordpress연동완료
- yaml파일 create로 워드프레스 서비스가 시작되면 그제서야 서비스에 IP가 할당된다.
```
kubectl get services | grep wordpress | awk '{print $4}' > WORDPRESS_IP
export WORDPRESS_IP=$(cat < WORDPRESS_IP)
```
위 쉘스크립트 명령으로 워드프레스 서비스객체의 IP를 얻어 내고
```
kubectl get pods | grep wordpress | awk '{print $1}' > WORDPRESS_POD
export WORDPRESS_POD=$(cat < WORDPRESS_POD)

```
위 쉘스크립트 명령으로 워드프레스파드의 아이디를 얻어온다.
```
sed "s/WORD_IP/$WORDPRESS_IP/g" ./data/wordpress.sql > ./wordpress.sql
sed "s/WORD_IP/$WORDPRESS_IP/g" ./data/wp-config.php > ./wp-config.php
```
위 쉘스크립트 명령으로 data/wordpress.sql과 data/wp-config.php의 환경변수 내용을 현재 실행중인 서비스IP의 정보가 반영된 파일인 srcs/wordpress.sql, srcs/wp-config.php를 로컬에 새롭게 만들어준다
```
kubectl cp wordpress.sql $WORDPRESS_POD:/tmp/
kubectl cp wp-config.php $WORDPRESS_POD:/etc/wordpress/
```
그리고나서 얻어온 Pod정보로 접근해 해당 파드의 컨테이너에 방금만든 파일을 넘겨주면 다른 파드에 돌고있는 mysql에 데이터를 넘겨줄 준비가 끝난상태
```
kubectl exec $WORDPRESS_POD -- sh /tmp/init-wordpress.sh
```
명령으로 워드프레스 파드의 컨테이너에 접근해 도커파일빌드시 넘겨준 실행스크립트를 실행시키면 mysql데이터베이스 서버에 wordpress가준비한 wordpress.sql데이터를 쏴줘서 데이터테이블을 만들고 연동이 가능해진다. 
### docker build -t ft_phpmyadmin ./srcs/phpmyadmin
php7패키지설치, phpmyadmin압축파일 설치, 압축해제 - 컨테이너의 /etc/phpmyadmin/으로 파일이동는 설정파일관해선 .yaml파일로 configMap제작후 deployment시 볼륨마운트하는 방식으로 연동
<br> server parameter 부분, host: 'mysql' (특정 서비스의 이름으로 접근가능. 쿠버네티스객체끼리), port: '3306', user: 'admin', password: 'sebaek'
### docker build -t ft_influxdb
influxdb설치. 빌드후 실행시 usr/sbin/influxdb로 시작. DB초기화 설정, 사용자 계정 설정들은 .yaml파일에서 진행
<br>influxdb-secret.yaml의 stringData:쪽에 DB초기화에 사용되는 전역변수와 그 값을 KEY:VALUE형태로 담을수있도록함
<br>influxdb-config.yaml에 configMap형태로 influxdb.conf내용 담아줌
<br>influxdb-deplyment.yaml에 ConfigMap정보를 담는 볼륨을 설정하고 이를 템플릿 스펙의 컨테이너에 /etc/influxdb/influxdb.conf로 볼륨 마운트
<br>데이터 영속성을 위해 PVC설정한후 볼륨 마운트.
### docker build -t ft_telegraf
마찬가지, 설치후 실행이 끝(usr/bin/telegraf) 설정은 yaml에서.
### docker build -t ft_grafana ./srcs/grafana
설치후 dashboards디렉토리, Provisioning디렉토리 카피해서 넘겨준뒤 실행. dashboard디렉토리의 json파일들은 어디서온거냐? 서비스들 다 시작한뒤 그라파나 켜서 대쉬보드를 직접만들뒤 json파일 형태를 복붙해서 로컬에 만들어준거임. Provisioning은? 그라파나 설치하면 생성되는데 요 안에 datasource.yaml은 연동할 데이터베이스의 이름과 데이터베이스 서버에대한 url을 설정할수있고 dashboard.yaml은 대쉬보드에대한 설정을 할 수 있다. 여기서 로컬에 만든 대쉬보드를 컨테이너에 넘겨줬을때 그 컨테이너상 대시보드들이 위치한 경로를 넘겨주면 미리 만들어둔 대시보드들을 그라파나에 접속해서 볼수있다.
