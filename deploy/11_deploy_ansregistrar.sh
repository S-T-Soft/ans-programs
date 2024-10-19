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

source ${env}.env

cd ../programs/ansregistrar || exit

echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}
ENDPOINT=${ENDPOINT}" > .env

leo build || exit 1

program=`jq -r '.program' program.json`
echo -e "Deploying \033[32m${program}\033[0m to \033[32m${env}\033[0m"

output=$(leo deploy --private-key "$PRIVATE_KEY" --network "${NETWORK}" --priority-fee 1 || exit 1)
echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Deployed \033[32m${program}\033[0m to \033[32m${env}\033[0m \033[31mFailed\033[0m"
else
  echo -e "Deployed \033[32m${program}\033[0m to \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi
