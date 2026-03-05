#!/bin/bash

host=$(hostname -I)

bootstrap=$(echo "$host":9092 | sed -e 's/ //')

while IFS='' read -r line || [[ -n "$line" ]]; do
    topic=$(echo "$line" | cut -f 1 -d" ")
    user=$(echo "$line" | cut -f 2 -d" ")
    operation=$(echo "$line" | cut -f 3 -d" ")

    if [[ $operation == 'read' ]]; then
        echo "/opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation $operation --topic $topic --command-config /home/elhbe1/kafka/security/client.config"
        echo "
        "
        /opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation read --group='*' --topic $topic --command-config /home/elhbe1/kafka/security/client.config
    else
        echo "/opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation $operation --topic $topic --command-config /home/elhbe1/kafka/security/client.config"
        echo "
        "
        /opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation write --topic $topic --command-config /home/elhbe1/kafka/security/client.config
    fi

done < "new_acls.txt"

exit 0
