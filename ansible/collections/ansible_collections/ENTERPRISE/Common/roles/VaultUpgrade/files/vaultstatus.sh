#!/bin/sh

export HOSTNAME=$(hostname -f)
export VAULT_ADDR="https://${HOSTNAME}:8200"


VAULT_STATUS=$(/usr/bin/vault status | grep ^Sealed | awk '{print $2}' )

if [ $VAULT_STATUS = "false" ]
then
     echo -n "Online"
else
     echo -n "Offline"
fi
