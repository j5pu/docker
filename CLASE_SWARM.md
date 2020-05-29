# Cluster
=========

Hay dos formas:
1.- [Docker Swarm (mode) cluster](https://docs.traefik.io/user-guide/swarm-mode/)
Este modo, docker swarm almacena la información de networking en los Raft logs de los swarm managers. [Swarm Mode Networking](https://docs.docker.com/engine/swarm/networking/)
El overlay network driver cread una red distribuida entre multiples Docker Daemon hosts. Va encima de las redes de los hosts.

Cuando se inicializa un Swarm o se une un Docker host al swarm, se crean dos redes en el host del docker.
1.- Una ***overlay network*** called: ***ingress*** (controla los ***swarm services***). Por defecto si no la contectas a una overlay que definas se conecta a la ingress.
    Se crean con:
```shell script
docker network create
```
Voy a hacer la 1.-
2.- Una ***bridged network*** llamada ***docker_gwbridge***, que ***conecta los daemons*** individuales con otros daemons que están en el swarm.

2.- [Docker Swarm cluster](https://docs.traefik.io/user-guide/swarm/)
Se llama Multi-host networking with standalone swarms (Swarm Classic) y usa un registro externo para las claves de networking. [Multi-host Standalone swarm](https://docs.docker.com/network/overlay-standalone.swarm/).
A brief description of the role goes here.

## 1.- [OVERLAY](https://docs.docker.com/network/overlay/)
To create an overlay network for ***use with swarm services***, use a command like the following:
```shell script
docker network create -d overlay my-overlay
```
To create an overlay network which can be used by ***swarm services*** **or** ***standalone containers*** se añade --attachable: 
```shell script
docker network create -d overlay --attachable my-attachable-overlay "<NAME>"
```

[Un manager no sea nodo tambien](https://docs.docker.com/engine/swarm/admin_guide/):
```shell script
docker node update --availability drain "<NODE>"
```
In most cases, you should shut down a node before removing it from a swarm with the docker node rm command. If a node becomes unreachable, unresponsive, or compromised you can forcefully remove the node without shutting it down by passing the --force flag. For instance, if node9 becomes compromised:
```shell script
docker node rm node9
docker node rm --force node9
```
### Operations for swarm services
Swarm services connected to the same overlay network effectively expose all ports to each other. For a port to be accessible outside of the service, that port must be published using the -p or --publish flag on docker service create or docker service update
```shell script
# Map TCP port 80 on the service to port 8080 on the routing mesh
-p 8080:80 or
-p published=8080,target=80
```
### Backup Swarm
Docker manager nodes store the swarm state and manager logs in the /var/lib/docker/swarm/ directory. In 1.13 and higher, this data includes the keys used to encrypt the Raft logs. Without these keys, you cannot restore the swarm.
1.-Stop Docker on the manager before backing up the data, so that no data is being changed during the backup. It is possi
2.- Back up the entire /var/lib/docker/swarm directory.
3.- Restart the manager.
[Restore](Restart the manager.)
Swarm is resilient to failures and the swarm can recover from any number of temporary node failures (machine reboots or crash with restart) or other transient errors. However, a swarm cannot automatically recover if it loses a quorum. Tasks on existing worker nodes continue to run, but administrative tasks are not possible, including scaling or updating services and joining or removing nodes from the swarm. The best way to recover is to bring the missing manager nodes back online. If that is not possible, continue reading for some options for recovering your swarm
Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.
## [Networking en Overlay networks](https://docs.docker.com/network/network-tutorial-overlay/):
It is recommended that you use separate overlay networks for each application or group of applications which will work together.

# [Container Training](https://container.training/swarm-selfpaced.yml.html)
MUY BUENA LA APLICACION, PORQUE TIENE SUS DOCKER FILES; COMPOSE Y EL GET, PUSH y WEBUI
# Correr la app
```shell script
git clone https://github.com/jpetazzo/container.training
cd  ~/container.training/stacks/dockercoins/
cd ~/container.training/dockercoins
docker-compose up
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs --tail 10 --follow
^S ^Q  # Parar y Seguir Log
docker-compose kill
```
# Escalar la app
```shell script
docker-compose up -d
top  # see CPU and memory and see idle cycles
vmstat 1  # to see i/O usage (si/so/bi/bo) (4 numbers should be almost 0, except bo for logging)
docker-compose up -d --scale worker=2
docker-compose up -d --scale worker=8
# Adding workers did not result in linear improvement. why?
httping -c 3 localhost:8001  # check latency of rng
httping -c 3 localhost:8002  # check latency of hasher
## bottelneck rng. Se necesita escalar rng
docker-compose down
```

[Composer: Containers are placed on a dedicated network, making links unnecessary](https://docs.docker.com/network/network-tutorial-overlay/)
Lo explica bien en la sección "Use an overlay network for standalone containers", this example demonstrates DNS container discovery -- specifically, how to communicate between standalone containers on different Docker daemons using an overlay network.
y en la sección "Communicate between a container and a swarm service". 
***Automatic DNS container discovery only works with unique container names.***
```shell script
# node1
host1$ docker swarm init --advertise-addr 10.10.1.3
host2$ docker swarm join --token SWMTKN-1-5n76zni83n8lwqjqjyrs9jmttoo2jeoydhbgqbhzrqbg634dgx-9kpp0d8hl6h3816su5a53rptb 10.10.1.3:2377
host1$ network create --driver=overlay --attachable test-net
host1$ docker run -it --name alpine1 --network test-net alpine
host2$ docker network ls
host2$ docker run -dit --name alpine2 --network test-net alpine
host2$ docker network ls
host1$ ping -c 2 alpine2
host2$ docker container stop alpine2
host2$ docker network ls
host2$ docker container rm alpine2
host2$ docker swarm leave
host1$ docker node rm node2
host1$ docker node ls
host2$ docker container stop alpine1
host1$ docker container rm alpine1
host1$ docker netwok ls
host1$ docker network rm test-net
host1$ docker node ls
host1$ docker swarm leave --force
```
Se puede cambiar el ***--advertise-addr*** port del **control** (manager/worker communication) plane pero tambien hay que cambiar el --listen-addr
```shell script
docker swarm init --advertise-addr 10.10.1.3:7777 --listen-addr 10.10.1.3:7777
docker swarm init --advertise-addr tun0:7777 --listen-addr tun0:7777

```
El **data** plane (trafico entre contenedores) se cambia con:
```shell script
docker swarm init --data-path-addr tun0
```
## Volumens
### Data Volumes
Data volumes are ***storage that exist independently of a container***. The lifecycle of data volumes under swarm services is similar to that under containers. Volumes outlive tasks and services, so their removal must be managed separately
if ***they don’t exist on a particular host when a task is scheduled there, they are created automatically***
```shell script
docker service create \
  --mount type=volume,src=<VOLUME-NAME>,dst=<CONTAINER-PATH>,volume-driver=<DRIVER>,volume-opt=<KEY0>=<VALUE0>,volume-opt=<KEY1>=<VALUE1>
  --name myservice \
  <IMAGE>
```
### Bind Mounts
Bind mounts are file system paths from the host where the ***scheduler deploys the container for the task***. Docker ***mounts the path into the container***. ***The file system path must exist before the swarm initializes the container for the task***
***Host bind mounts are non-portable***
```shell script
docker service create \
  --mount type=bind,src=<HOST-PATH>,dst=<CONTAINER-PATH> \
  --name myservice \
  <IMAGE>
```