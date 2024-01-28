#!/bin/bash
sudo sysctl -w vm.max_map_count=262144

docker-compose up setup
docker-compose up -d

echo "Waiting for Kibana to be ready..."
until curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/login -u "elastic:$ELASTIC_PASSWORD" | grep 200 > /dev/null; do
    sleep 5
done

ELASTIC=`docker-compose exec elasticsearch bin/elasticsearch-reset-password --batch --user elastic`
LOGSTASH=`docker-compose exec elasticsearch bin/elasticsearch-reset-password --batch --user logstash_internal`
KIBANA=`docker-compose exec elasticsearch bin/elasticsearch-reset-password --batch --user kibana_system`

# Password for the [elastic] user successfully reset.
# New value: 7S3cJea6e9sch_X5r*rL

# Replace usernames and passwords in configuration files

ELASTIC_PASSWORD=`echo $ELASTIC | awk '/New value:/ {print $NF}'`
LOGSTASH_INTERNAL_PASSWORD=`echo $LOGSTASH | awk '/New value:/ {print $NF}'`
KIBANA_SYSTEM_PASSWORD=`echo $KIBANA | awk '/New value:/ {print $NF}'`

sed -i "s/ELASTIC_PASSWORD/$ELASTIC_PASSWORD/g" .env
sed -i "s/LOGSTASH_INTERNAL_PASSWORD/$LOGSTASH_INTERNAL_PASSWORD/g" .env
sed -i "s/KIBANA_SYSTEM_PASSWORD/$KIBANA_SYSTEM_PASSWORD/g" .env

docker-compose up -d logstash kibana

echo "Waiting for Kibana to be ready..."
until curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/login -u "elastic:$ELASTIC_PASSWORD" | grep 200 > /dev/null; do
    sleep 5
done

cat test.log | nc -q0 localhost 50000