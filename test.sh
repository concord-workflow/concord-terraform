#!/usr/bin/env bash

source "$HOME/.concord/profile"
source "$PWD/.test/functions.bash"

basedir=${PWD}
version="0.12"
provider="aws"
targetDir="${basedir}/target/${version}"
testResults="${targetDir}/test-results.txt"
awsCredentialsScript="${basedir}/.test/*get-aws-profile.sh"
awsProfile="${AWS_PROFILE}"
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
          testDir="${targetDir}/${module}"
          processFiles "${testDir}" "${modulesPath}" "${modulePath}"
          if [ -f terraform-requirements ]; then
            for requirement in $(cat terraform-requirements)
            do
              cp ${modulesPath}/${requirement}/*.tf ${targetDir}
              cp ${modulesPath}/${requirement}/*.json ${targetDir} 2>/dev/null || :
            done
          fi

          fixturesDir="fixtures"
          if [ -d "${fixturesDir}" ]; then
            (
              cd ${fixturesDir}
              processFiles "${targetDir}" "${modulesPath}" "${PWD}"
              cd ${targetDir}
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
            cd ${targetDir}
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
                      cd ${targetDir}
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

options=$(getopt -o h,d,m,a,td --long help,debug,module,all,terraform-destroy -n 'parse-options' -- "$@")

if [ $? != 0 ]; then
  echo "Failed parsing options." >&2
  exit 1
fi

action=""

while [[ $# -gt 0 ]]; do
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
      moduleTargetDir="${targetDir}/${module}"
      if [ -d "${moduleTargetDir}" ]; then
        cd ${moduleTargetDir}
        echo "Destroing module[${module}]"
        echo "Module directory[${moduleTargetDir}]"
        ( terraform destroy -auto-approve )
        if [ -d fixtures ]; then
          ( cd fixtures/concord-terraform; terraform destroy -auto-approve )
        fi
      fi
    )
  done
else
  mkdir -p ${targetDir} 2>/dev/null
  
  for module in ${modules}
  do
    testModule "${module}" "${modulesPath}/${module}" "${modulesPath}"
  done

  displayTestResults ${testResults}
fi
