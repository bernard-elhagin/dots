#!/bin/env bash

filename="new_topics.txt"

bootstrap=$(echo "$(hostname -i)":9092 | tr -d ' ')
bootstrap=localhost:9092

workers=$(/opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server "$bootstrap") # --command-config "$HOME"/security/client.properties)

bootstrapserver=$(grep "id:" <<<"$workers" | cut -f1 -d" " | paste -sd",")
replication=$(grep -c "id:" <<<"$workers")

echo $bootstrapserver; echo $replication; exit

while read topic retention partitions bootstrap; do
    retention_ms=$((retention*24*60*60*1000))

    echo "/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server $bootstrapserver --replication-factor $replication --partitions $partitions --topic $topic --config retention.ms=$retention_ms"
    /opt/kafka/bin/kafka-topics.sh --create --bootstrap-server $bootstrapserver --replication-factor $replication --partitions $partitions --topic $topic --config retention.ms=$retention_ms
done < "$filename"
exit 0
