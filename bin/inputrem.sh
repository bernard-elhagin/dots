#!/usr/bin/env bash

_ISACTIVE=$(systemctl is-active input-remapper.service)

if [ $_ISACTIVE = "active" ]; then
    sudo systemctl stop input-remapper.service
else
    sudo systemctl restart input-remapper.service
    input-remapper-control --command autoload
fi
