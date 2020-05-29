```shell script
ssh node1
docker run -it --name alpine1 --network attached alpine
ping -c 2 alpine2
exit
# clean
docker container stop alpine1
docker container rm alpine1
docker image rm alpine
```
```shell script
ssh node2
docker run -dit --name alpine2 --network attached alpine
docker network ls
docker container stop alpine2
docker container rm alpine2
docker image rm alpine
```