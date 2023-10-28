#!/usr/bin/env bash

env="dev"

# tld ans
name=""

for arg in "$@"; do
  case $arg in
    --env=dev)
      shift
      ;;
    --env=prod)
      env="prod"
      shift
      ;;
    --name=*)
      name="${arg#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

if [[ -z "$name" ]]; then
  echo "Error: --name parameter is required"
  exit 1
fi

name_arr=$(python3 -c "s = '$name'; b = s.encode('utf-8') + b'\0' * (64 - len(s)); name = [int.from_bytes(b[i*16 : i*16+16], 'little') for i in range(4)]; print(f'[{name[0]}u128, {name[1]}u128, {name[2]}u128, {name[3]}u128]')")

source ${env}.env

program=`jq -r '.program' ../programs/ansregistrar/program.json`

echo -e "Register \033[32m${name}.ans\033[0m from \033[32m${program}\033[0m in \033[32m${env}\033[0m"

if [[ -z "${FEE_RECORD}" ]]; then
  output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
           --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
           ${program} register_fld "${name_arr}" ${ADDRESS} "${RECORD}")
else
  output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
           --record "${FEE_RECORD}" \
           --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
           ${program} register_fld "${name_arr}" ${ADDRESS} "${RECORD}")
fi

echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Register \033[32m${name}.ans\033[0m from \033[32m${program}\033[0m in \033[32m${env}\033[0m \033[31mFailed\033[0m"
  exit 1
else
  echo -e "Register \033[32m${name}.ans\033[0m from \033[32m${program}\033[0m in \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi

if [[ -n "${FEE_RECORD}" ]]; then
  sleep 30

  ${root}/update_env.sh ${tx} ${env}.env ".fee.transition"
fi