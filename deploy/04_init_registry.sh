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

# if env is testnet or dev, use testnet-api.aleonames.id
# if env is mainnet, use api.aleonames.id
if [[ $env == "mainnet" ]]; then
  base_uri="https://api.aleonames.id/token/"
else
  base_uri="https://testnet-api.aleonames.id/token/"
fi

base_uri_arr=$(node stringEncode.ts $base_uri 4)

root=$(pwd)
env_file="${root}/${env}.env"
source $env_file

cd ../programs/registry || exit

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}
ENDPOINT=${ENDPOINT}" > .env

program=`jq -r '.program' program.json`

echo -e "Initialize \033[32m${program}\033[0m in \033[32m${env}\033[0m"

if [[ -z "${FEE_RECORD}" ]]; then
  output=$(leo execute -b --private-key "${PRIVATE_KEY}" -p "${program%.aleo}" \
   --network "${NETWORK}" initialize_collection "${base_uri_arr}")
else
  output=$(leo execute -b --private-key "${PRIVATE_KEY}" --record "${FEE_RECORD}" \
   --network "${NETWORK}" -p "${program%.aleo}" initialize_collection "${base_uri_arr}")
fi

echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Initialized \033[32m${program}\033[0m to \033[32m${env}\033[0m \033[31mFailed\033[0m"
  exit 1
else
  echo -e "Initialized \033[32m${program}\033[0m to \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi

if [[ -n "${FEE_RECORD}" ]]; then
  sleep 30

  ${root}/update_env.sh ${tx} ${env_file} ".fee.transition"
fi