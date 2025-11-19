#!/bin/bash

export HOSTNAME=$(hostname -f)
export VAULT_ADDR="https://${HOSTNAME}:8200"


VAULT_STATUS=$(/usr/bin/vault status | grep ^Sealed | awk '{print $2}' )

if [ $VAULT_STATUS = "false" ]
then
     echo -n "Online"
else
     vault operator unseal {{ unseal_token1d }}
     vault operator unseal {{ unseal_token2d }}
     vault operator unseal {{ unseal_token3d }}
fi

/usr/bin/vault status | grep ^Sealed
