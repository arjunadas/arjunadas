# get all names of the running containers
b=(`docker ps | awk '{print $ 13}' | tail -n +2`)
# copy certificates into containers
for name in ${b[@]}; do docker cp /opt/certupdate/tempcert/cert.pfx $name:/app ; done
# restart all containers
for name in ${b[@]}; do docker restart $name ; done
