#!/bin/bash

# na podstawie host IP tworzymy bootstrap-server
if [[ ! host=$(hostname -I 2>/dev/null) ]]; then
    echo ""
else
    host=$(hostname -i)
fi

bootstrap=$(echo "$host":9092 | sed -e 's/ //')

echo $bootstrap; exit 0

bootstrap=$(kafka-broker-api-versions.sh --bootstrap-server "$bootstrap" --command-config "$HOME"/security/client.properties | grep "id:" | cut -f1 -d" " | paste -sd",")

#kafka-acls.sh --bootstrap-server 10.67.186.8 --list --admin.config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.8 --list --admin-config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.8 --list --asdf
#kafka-acls.sh --bootstrap-server 10.67.186.8 --list 
#kafka-acls.sh --bootstrap-server 10.67.186.8:9092 --list 
#kafka-acls.sh --bootstrap-server 10.67.186.8:9092 --lis
#kafka-acls.sh --bootstrap-server 10.67.186.8:9092 --help
#kafka-acls.sh --bootstrap-server 10.67.186.8:9092 --help | less
#kafka-acls.sh --bootstrap-server 10.67.186.8:9092 --help 2>/tmp/less
#kafka-acls.sh --bootstrap-server 10.67.186.8 --list --command.config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.8 --list --command-config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.8:9092 --list --command-config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.4:9092 --list --command-config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --list --command-config client.config
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --add --allow-principal User:test --operation write --topic test
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --add --allow-principal User:test --operation write --topic test --command-config kafka/config/ssl/client.config
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --add --allow-principal User:test --operation read --group='*' --topic test --command-config kafka/config/ssl/client.config
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --add --allow-principal User:connect-debezium --operation read --group='*' --topic connect-test --command-config kafka/config/ssl/client.config
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --add --allow-principal User:connect-debezium --operation write --topic connect-test --command-config kafka/config/ssl/client.config
#kafka-acls.sh --bootstrap-server 10.67.186.5:9092 --list --command-config kafka/config/ssl/client.config


#while IFS='' read -r line || [[ -n "$line" ]]; do
#    topic=$(echo "$line" | cut -f 1 -d" ")
#    retention=$(echo "$line" | cut -f 2 -d" ")
#    partitions=$(echo "$line" | cut -f 3 -d" ")
#
#    retention_ms=$((retention*24*60*60*1000))
#
#    echo "/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server $bootstrap --replication-factor $replication --partitions $partitions --topic $topic --config retention.ms=$retention_ms"
#    echo "
#    "
#    /opt/kafka/bin/kafka-topics.sh --create --bootstrap-server "$bootstrap" --replication-factor "$replication" --partitions "$partitions" --topic "$topic" --config retention.ms=$retention_ms
#done < "$filename"
#exit 0
