## Steps to migrate data from legacy QUADS 1.0 /opt/quads/data/ports to mongodb
for h in $(cat /root/quads-ports-data/host-lists/cloud01-systems); do quads --define-host $h --default-cloud cloud01 --host-type vendor;done

for host in $(cat /root/quads-ports-data/host-lists/cloud01-systems); do for line in $(cat /root/quads-ports-data/ports/$host); do $line | awk -F, -v host="$host" '{printf "quads --add-interface %s --interface-mac %s --interface-ip %s --interface-port %s --host %s\n", $1 , $2, $3, $5, host}' ; done; done

docker exec quads python quads/tools/vlan_yaml_to_mongo.py --yaml conf/vlans.yml

for host in $(cat /root/quads-ports-data/host-lists/cloud01-systems); do for line in $(cat /root/quads-ports-data/ports/$host); do echo $line | awk -F, -v host="$host" '{printf "quads --add-interface %s --interface-mac %s --interface-ip %s --interface-port %s --host %s\n", $1 , $2, $3, $5, host}' ; done; done > /tmp/add-int

for cmd in $(cat /tmp/add-int); do $cmd; done
