#!/bin/bash

host=$(hostname -I)

bootstrap=$(echo "$host":9092 | sed -e 's/ //')

while IFS='' read -r line || [[ -n "$line" ]]; do
    topic=$(echo "$line" | cut -f 1 -d" ")
    user=$(echo "$line" | cut -f 2 -d" ")
    operation=$(echo "$line" | cut -f 3 -d" ")

    if [[ $operation == 'read' ]]; then
        operation="read --group='*'"
    fi

    echo "kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation $operation --topic $topic --command-config ~/kafka/security/client.config"
    echo "
    "
    kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation $operation --topic $topic --command-config ~/kafka/security/client.config
done < "new_acls.txt"

exit 0
