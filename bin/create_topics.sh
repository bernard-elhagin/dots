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

filename="new_topics.txt"

while IFS=' ' read topic retention partitions; do
    retention_ms=$((retention*24*60*60*1000))

    echo "/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 3 --partitions $partitions --topic $topic --config retention.ms=$retention_ms"
    echo "
    "
done < "$filename"
exit 0
