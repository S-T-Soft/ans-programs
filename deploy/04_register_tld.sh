#!/usr/bin/env bash

env="dev"

# tld ans
tld="{data1: 7564897u128, data2: 0u128, data3: 0u128, data4: 0u128}"

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
echo "NETWORK=${NETWORK}
PRIVATE_KEY=${PRIVATE_KEY}" > ../programs/registry/.env

program=`grep -o '"program": *"[^"]*' ../programs/registry/program.json | sed 's/"program": *"//'`
registrar=`grep -o '"program": *"[^"]*' ../programs/ansregistrar/program.json | sed 's/"program": *"//'`

mkdir -p ../programs/get_address/src
echo "import get_caller.leo;
program ${registrar} {
    transition main() -> (address, address) {
        return get_caller.leo/who();
    }
}" > ../programs/get_address/src/main.leo
echo "{
    \"program\": \"${registrar}\",
    \"version\": \"0.0.1\",
    \"description\": \"\",
    \"license\": \"MIT\"
}" > ../programs/get_address/program.json

cd ../programs/get_address || exit
registrar_address=$(leo run | awk 'match($0, /aleo[0-9a-zA-Z]+/) {print substr($0, RSTART, RLENGTH); exit}')

echo -e "Set tld \033[32m.ans\033[0m to \033[32m${registrar}(${registrar_address})\033[0m in \033[32m${env}\033[0m"

output=$(snarkos developer execute --private-key "${PRIVATE_KEY}" --query "${ENDPOINT}" \
 --record "${FEE_RECORD}" \
 --broadcast "${ENDPOINT}/testnet3/transaction/broadcast" \
 ${program} register_tld ${registrar_address} "${tld}")
echo "${output}"
tx=$(echo ${output} | awk 'match($0, /[^0-9a-zA-Z](at[0-9a-zA-Z]+)[^0-9a-zA-Z]/) {print substr($0, RSTART + 1, RLENGTH - 2); exit}')

echo -e "Set tld \033[32m.ans\033[0m for \033[32m${registrar}\033[0m in \033[32m${env}\033[0m successfully, tx: \033[32m${tx}\033[0m"

sleep 30

${root}/update_env.sh ${tx} ${env}.env ".fee.transition"