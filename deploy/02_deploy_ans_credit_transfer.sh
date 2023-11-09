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

source ${env}.env

cd ../programs/credit_transfer || exit

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}" > .env

leo build || exit 1

program=`jq -r '.program' program.json`
echo -e "Deploying \033[32m${program}\033[0m to \033[32m${env}\033[0m"

output=$(snarkos developer deploy ${program} --private-key "$PRIVATE_KEY" --query ${ENDPOINT} \
 --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
 --path "./build/" --priority-fee 1 || exit 1)
echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Deployed \033[32m${program}\033[0m to \033[32m${env}\033[0m \033[31mFailed\033[0m"
else
  echo -e "Deployed \033[32m${program}\033[0m to \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi
