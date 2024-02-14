#!/usr/bin/env bash

env="dev"

for arg in "$@"; do
  case $arg in
    --env=*)
      env="${arg#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

if [[ ! -f ${env}.env ]]; then
  echo "Error: ${env}.env does not exist"
  exit 1
fi

root=$(pwd)
env_file="${root}/${env}.env"
source $env_file

cd ../programs/ansregistrar || exit

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}" > .env

program=`jq -r '.program' program.json`

echo -e "Update \033[32m${program}\033[0m Minting Flag in \033[32m${env}\033[0m"

if [[ -z "${FEE_RECORD}" ]]; then
  output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
   --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
   ${program} set_minting_flag 1u128 1u128)
else
  output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
   --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
   --record "${FEE_RECORD}" \
   ${program} set_minting_flag 1u128 1u128)
fi

echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Update \033[32m${program}\033[0m to \033[32m${env}\033[0m \033[31mFailed\033[0m"
  exit 1
else
  echo -e "Update \033[32m${program}\033[0m to \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi

if [[ -n "${FEE_RECORD}" ]]; then
  sleep 30

  ${root}/update_env.sh ${tx} ${env_file} ".fee.transition"
fi