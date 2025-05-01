#!/bin/env bash

# filename to argument skryptu wskazujący na plik
# z listą topiców do utworzenia w formacie:
#
# nazwa.topika1 retencja_w_dniach partycje
# nazwa.topika2 retencja_w_dniach partycje
# nazwa.topika3 retencja_w_dniach partycje
#
# Domyślnie, bez podania $1 brany jest plik o nazwie
# new_topics.txt

if [ -z $1 ]
then
    filename="new_topics.txt"
else
    filename="$1"
fi

# na podstawie host IP tworzymy bootstrap-server oraz liczymy
# replication factor
host=$(hostname -I)

bootstrap=$(echo $host:9092 | sed -e 's/ //')

bootstrap=$(kafka-broker-api-versions.sh --bootstrap-server $bootstrap --command-config $HOME/security/client.properties | grep "id:" | cut -f1 -d" " | paste -sd",")
replication=$(kafka-broker-api-versions.sh --bootstrap-server $bootstrap --command-config $HOME/security/client.properties | grep "id:" | wc -l)

while IFS='' read -r line || [[ -n "$line" ]]; do
    topic=$(echo "$line" | cut -f 1 -d" ")
    retention=$(echo "$line" | cut -f 2 -d" ")
    partitions=$(echo "$line" | cut -f 3 -d" ")

    retention_ms=$((retention*24*60*60*1000))

    echo "/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server $bootstrap --replication-factor $replication --partitions $partitions --topic "$topic" --config retention.ms=$retention_ms"
    echo "
    "
    /opt/kafka/bin/kafka-topics.sh --create --bootstrap-server $bootstrap --replication-factor $replication --partitions $partitions --topic "$topic" --config retention.ms=$retention_ms"
done < "$filename"
exit 0
