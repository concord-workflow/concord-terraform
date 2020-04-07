#!/usr/bin/env bash

source "$HOME/.concord/profile"
source "$PWD/.test/functions.bash"

basedir=${PWD}
version="0.12"
provider="aws"
testResults="${basedir}/test-results.txt"
awsCredentials="${basedir}/.test/*get-aws-profile.sh"
awsProfile="${CONCORD_ACCOUNT}-${CONCORD_USER}"
modulesPath="${basedir}/${version}/${provider}"

function testModule() {
  module=$1 #moduleId
  modulePath=$2
  modulesPath=$3 # basedir of actual modules

  if [ -d ${modulePath} ]; then
    (
      cd ${modulePath}
      if [ -d tests ]; then
        echo "Testing '${module}' module ..."

        (
          cd tests
          terraformDir="concord-terraform"
          processFiles "${terraformDir}" "${modulesPath}" "${modulePath}"

          if [ -f terraform-requirements ]; then
            for requirement in $(cat terraform-requirements)
            do
              cp ${modulesPath}/${requirement}/*.tf ${terraformDir}
            done
          fi

          fixturesDir="fixtures"
          if [ -d "${fixturesDir}" ]; then
            (
              cd ${fixturesDir}
              processFiles "${terraformDir}" "${modulesPath}" "${PWD}"
              cd ${terraformDir}
              processTerraformVars
              if [ ! -f .noterraform ]; then
                terraform init -no-color
                terraform validate -no-color
                terraform apply -auto-approve -no-color
              fi
            )
          fi

          # Execute
          (
            cd ${terraformDir}
            processTerraformVars
            [ -f terraform-pre-tests ] && echo && bash ./terraform-pre-tests

            if [ ! -f .noterraform ]; then
              start=$SECONDS
              terraform init -no-color
              terraform validate -no-color
              terraform apply -auto-approve -no-color
              terraform output -json > terraform-outputs.json
              [ -f terraform-tests.bats ] && echo && bats terraform-tests.bats
              if [ "$?" -eq 0 ]; then
                # Currently we only run terraform destroy if the tests are successful
                if [ ! -f .nodestroy ]; then
                  terraform destroy -auto-approve -no-color
                  # Destroy the test fixtures
                  if [ -d "../${fixturesDir}" ]; then
                    (
                      cd ../${fixturesDir}
                      cd ${terraformDir}
                      terraform destroy -auto-approve -no-color
                    )
                  fi
                fi
                testState="OK"
              else
                testState="FAIL"
              fi
              duration=$(( SECONDS - start ))
              echo "${module}:${testState}:${duration}" >> ${testResults}
            fi
          )
          # Stepping out of module
        )
      fi
    )
  fi
}

function cmd() {
  basename $0
}

function usage() {
  echo "\
`cmd` [OPTIONS...]
-h, --help; Show help
-d, --debug; Turn on 'set -eox pipefail'
-m, --module; Run the specified modules
-a, --all; Run all modules
-td, --terraform-destroy
" | column -t -s ";"
}

options=$(getopt -o d:m:a:td --long debug:,module:,all:,terraform-destroy: -n 'parse-options' -- "$@")

if [ $? != 0 ]; then
  echo "Failed parsing options." >&2
  exit 1
fi

while true; do
  case "$1" in
    -h  | --help) usage; exit;;
    -d  | --debug) set -eox pipefail; shift 1;;
    -m  | --module) modules=$2; shift 2;;
    -a  | --all ) modules=`ls ${modulesPath}`; shift 1;;
    -td | --terraform-destroy) action=terraform-destroy; shift 1;;
    -- ) shift; break ;;
    "" ) break ;;
    * ) echo "Unknown option provided ${1}"; usage; exit 1; ;;
  esac
done

[ -f "${testResults}" ] && rm -f ${testResults}

if [ "$action" = "terraform-destroy" ]; then
  for module in ${modules}
  do
    (
      cd ${modulesPath}/${module}/tests
      ( cd concord-terraform; terraform destroy -auto-approve)
      if [ -d fixtures ]; then
        ( cd fixtures/concord-terraform; terraform destroy -auto-approve)
      fi
    )
  done
else
  for module in ${modules}
  do
    testModule "${module}" "${modulesPath}/${module}" "${modulesPath}"
  done

  displayTestResults ${testResults}
fi