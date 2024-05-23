#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # Default

function process_object() {
  echo -e "${BLUE}Processing object:${NC}"
  echo $1 | yq -P --unwrapScalar=true
  collection=$(echo "$1" | yq -r '.collection')
  folder=$(echo "$1" | yq -r '.folder')
  environment=$(echo "$1" | yq -r '.environment')
  envs=$(echo "$1" | yq -r '.env_override | to_entries | map("--env-var \(.key)=${\(.value)}") | join(" ")')
  env_count=$(echo "$1" | yq '.env_override | length')
  pushd $collectionPath/$collection >> /dev/null # don't need the log spam so >>
  if (( env_count > 0 )); then
    display_cmd=$(echo "bru run $folder --env $environment $envs")
    cmd=$(eval echo "bru run $folder --env $environment $envs")
    # Don't output the values of the environments in case it's a secret.
    echo "$display_cmd"
    ${cmd}
  else
    echo "cmd: bru run $folder --env $environment"
    bru run $folder --env $environment
  fi
  run_result=$?
  popd >> /dev/null # don't need the log spam
  return $run_result
}

collectionPath=./workflows
all_tests_passed=true
failed_folders=()

# Check if a file is provided as an argument
if [ $# -eq 0 ]; then
  echo "Usage: $0 <yaml_testsuite_file>"
  exit 1
fi

# Read the test suite file and pipe each object to the runner
test_id=0
while read -r object; do
  process_object "$object"
  if [ $? -ne 0 ]; then
    test_name=$(echo "$object"| yq -r '"\(.collection)/\(.folder)"')
    all_tests_passed=false
    failed_folders+=("Test #${test_id}: $test_name")
  fi
  ((test_id++))
done < <(yq '.[]' -o=json -I=0 "$1")
# Check if all tests passed
if [ "$all_tests_passed" = false ]; then
  echo ""
  echo -e "${RED}Test failures in:"
  for folder in "${failed_folders[@]}"; do
      echo -e " - $folder"
  done
  echo -e "${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}All tests have been run successfully.${NC}"
  exit 0
fi
