#!/usr/bin/env bash

env="dev"

# tld ans
name=""
parent="3601410589032411677092457044111621862970800028849492457114786804129430260029field"

for arg in "$@"; do
  case $arg in
    --env=*)
      env="${arg#*=}"
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

if [[ ! -f ${env}.env ]]; then
  echo "Error: ${env}.env does not exist"
  exit 1
fi

if [[ -z "$name" ]]; then
  echo "Error: --name parameter is required"
  exit 1
fi

name_arr=$(python3 -c "s = '$name'; b = s.encode('utf-8') + b'\0' * (64 - len(s)); name = [int.from_bytes(b[i*16 : i*16+16], 'little') for i in range(4)]; print(f'[{name[0]}u128, {name[1]}u128, {name[2]}u128, {name[3]}u128]')")

source ${env}.env

program=`jq -r '.program' ../programs/ansregistrar/program.json`

echo -e "Register \033[32m${name}.ans\033[0m from \033[32m${program}\033[0m in \033[32m${env}\033[0m"

output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" --network 1 \
  -b "${ENDPOINT}/testnet/transaction/broadcast" \
  "${program}" register_fld_public "${name_arr}" "${parent}" "${ADDRESS}")

echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Register \033[32m${name}.ans\033[0m from \033[32m${program}\033[0m in \033[32m${env}\033[0m \033[31mFailed\033[0m"
  exit 1
else
  echo -e "Register \033[32m${name}.ans\033[0m from \033[32m${program}\033[0m in \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi
