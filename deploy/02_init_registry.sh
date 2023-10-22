#!/usr/bin/env bash

env="dev"

for arg in "$@"; do
  case $arg in
    --env=dev)
      shift
      ;;
    --env=prod)
      env="prod"
      shift
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

root=$(pwd)
env_file="${root}/${env}.env"
source $env_file

cd ../programs/registry || exit

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}" > .env

program=`grep -o '"program": *"[^"]*' program.json | sed 's/"program": *"//'`

echo -e "Initialize \033[32m${program}\033[0m in \033[32m${env}\033[0m"

output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
 --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
 --record "${FEE_RECORD}" \
 ${program} initialize_collection \
 340282366920938463463374607431768211455u128 \
 5459521u128 \
 "{data0: 148070927714570416107472362983216411752u128, data1: 246277052701588008591160357696659822u128, data2: 0u128, data3: 0u128}")
echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

echo -e "Initialized \033[32m${program}\033[0m in \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"

sleep 30

${root}/update_env.sh ${tx} ${env_file} ".fee.transition"