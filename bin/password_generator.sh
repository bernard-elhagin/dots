#!/bin/bash

i=0
while (( i < $1 )); do
    tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -z -c $2 && echo
    ((i++))
done
