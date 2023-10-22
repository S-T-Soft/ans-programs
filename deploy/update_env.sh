#!/usr/bin/env bash

tx=$1
env_file=$2
position=$3

source $env_file

ciphertext=$(curl ${ENDPOINT}/testnet3/transaction/${tx} | jq -r "${position}.outputs[] | select(.type==\"record\") | .value")
record=$(snarkos developer decrypt --view-key "${VIEW_KEY}" --ciphertext "${ciphertext}" | tr -d '\n')

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}
VIEW_KEY=${VIEW_KEY}
ADDRESS=${ADDRESS}
ENDPOINT=${ENDPOINT}
FEE_RECORD=\"${record}\"" > ${env_file}