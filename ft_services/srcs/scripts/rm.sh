docker system prune -a

#rm existing imgs etc and stop containers
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

rm -r ~/Library/Caches/*
