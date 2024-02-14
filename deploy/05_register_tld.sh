#!/usr/bin/env bash

env="dev"

# tld ans
tld="ans"

for arg in "$@"; do
  case $arg in
    --env=*)
      env="${arg#*=}"
      shift
      ;;
    --tld=*)
      tld="${arg#*=}"
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
echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}" > ../programs/registry/.env

program=`jq -r '.program' ../programs/registry/program.json`
registrar=`jq -r '.program' ../programs/ansregistrar/program.json`

name_arr=$(python3 -c "s = '$tld'; b = s.encode('utf-8') + b'\0' * (64 - len(s)); name = [int.from_bytes(b[i*16 : i*16+16], 'little') for i in range(4)]; print(f'[{name[0]}u128, {name[1]}u128, {name[2]}u128, {name[3]}u128]')")

mkdir -p ../programs/get_address/src
echo "import get_caller.aleo;
program ${registrar} {
    transition main() -> (address, address) {
        return get_caller.aleo/who();
    }
}" > ../programs/get_address/src/main.leo
echo "{
    \"program\": \"${registrar}\",
    \"version\": \"0.0.1\",
    \"description\": \"\",
    \"license\": \"MIT\",
    \"dependencies\": [
    {
      \"name\": \"get_caller.aleo\",
      \"location\": \"local\",
      \"path\": \"get_caller\"
    }
  ]
}" > ../programs/get_address/program.json

cd ../programs/get_address || exit
registrar_address=$(leo run | awk 'match($0, /aleo[0-9a-zA-Z]+/) {print substr($0, RSTART, RLENGTH); exit}')

echo -e "Set tld \033[32m.${tld}(${name_arr})\033[0m to \033[32m${registrar}(${registrar_address})\033[0m in \033[32m${env}\033[0m"

if [[ -z "${FEE_RECORD}" ]]; then
  output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
           --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
           ${program} register_tld "${registrar_address}" "${name_arr}")
else
  output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
           --record "${FEE_RECORD}" \
           --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
           ${program} register_tld "${registrar_address}" "${name_arr}")
fi

echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

if [[ -z "$tx" ]]; then
  echo -e "Set tld \033[32m.${tld}\033[0m for \033[32m${program}\033[0m to \033[32m${env}\033[0m \033[31mFailed\033[0m"
  exit 1
else
  echo -e "Set tld \033[32m.${tld}\033[0m for \033[32m${program}\033[0m to \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"
fi

if [[ -n "${FEE_RECORD}" ]]; then
  sleep 30

  ${root}/update_env.sh ${tx} ${env}.env ".fee.transition"
fi