#!/usr/bin/env bash

env="dev"
setting=3u32

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

cd ../programs/registry || exit

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}" > .env

program=`jq -r '.program' program.json`

echo -e "Set setting \033[32m${setting}\033[0m for \033[32m${program}\033[0m in \033[32m${env}\033[0m"

if [[ -z "${FEE_RECORD}" ]]; then
  output=$(leo execute -b --private-key "${PRIVATE_KEY}" --endpoint "${ENDPOINT}" \
   -p "${program%.aleo}" --network "${NETWORK}" update_toggle_settings ${setting})
else
  output=$(leo execute -b --private-key "${PRIVATE_KEY}" --endpoint "${ENDPOINT}" \
   --record "${FEE_RECORD}" -p "${program%.aleo}" --network "${NETWORK}" update_toggle_settings ${setting})
fi

echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Set setting \033[32m${setting}\033[0m for \033[32m${program}\033[0m in \033[32m${env}\033[0m \033[31mFailed\033[0m"
  exit 1
else
  echo -e "Set setting \033[32m${setting}\033[0m for \033[32m${program}\033[0m in \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi

if [[ -n "${FEE_RECORD}" ]]; then
  sleep 30

  ${root}/update_env.sh ${tx} ${env_file} ".fee.transition"
fi