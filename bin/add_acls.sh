#!/usr/bin/env bash

host=$(hostname -I)
bootstrap=$(echo "$host":9092 | tr -d ' ')

while read -r topic user operation; do

    if [[ $operation == 'read' ]]; then
        echo "/opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation $operation --topic $topic --command-config /home/elhbe1/kafka/security/client.config"

        /opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation read --group='*' --topic $topic --command-config /home/elhbe1/kafka/security/client.config
    else
        echo "/opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation $operation --topic $topic --command-config /home/elhbe1/kafka/security/client.config"

        /opt/kafka/bin/kafka-acls.sh --bootstrap-server $bootstrap --add --allow-principal User:$user --operation write --topic $topic --command-config /home/elhbe1/kafka/security/client.config
    fi

done < "new_acls.txt"

exit 0
