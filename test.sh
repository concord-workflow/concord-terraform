#!/usr/bin/env bash

source "$HOME/.concord/profile"
source "$PWD/.test/functions.bash"

basedir=${PWD}
version="0.12"
provider="aws"

targetDir="${basedir}/target/${version}"
#rm -rf ${targetDir} 2>/dev/null
mkdir -p ${targetDir} 2>/dev/null

testResults="${targetDir}/test-results.txt"
awsCredentialsScript="${basedir}/.test/*get-aws-profile.sh"
awsProfile="${AWS_PROFILE}"
modulesPath="${basedir}/${version}/${provider}"

if [ -z "${AWS_CREDENTIALS}" ]; then
  echo 'You must define the envar ${AWS_CREDENTIALS}'.
  exit
elif [ ! -f ${AWS_CREDENTIALS} ]; then
  echo "The specified AWS_CREDENTIALS file '${AWS_CREDENTIALS}' does not exist. You must provide a valid credentials file."
  exit
fi

if [ -z "${AWS_PROFILE}" ]; then
  echo 'You must define the envar ${AWS_PROFILE}'.
  exit
else
  ${awsCredentials} --profile=${AWS_PROFILE} --key > /dev/null 2>&1
  if [ "$?" = "5" ]; then
    echo "The specified profile '${AWS_PROFILE}' does not exist in '${AWS_CREDENTIALS}'. You must provide a valid profile."
    exit
  fi
fi

if [ -z "${AWS_PEM}" ]; then
  echo 'You must define the envar ${AWS_PEM}'.
  exit
elif [ ! -f ${HOME}/.concord/${AWS_PEM} ]; then
  echo "The specified AWS_PEM file '${HOME}/.concord/${AWS_PEM}' does not exist. You must provide a valid credentials file."
  exit
fi

function testModule() {
  module=$1 #moduleId
  modulePath=$2
  modulesPath=$3 # basedir of actual modules

  if [ -d ${modulePath} ]; then
    (
      cd ${modulePath}
      echo "Testing '${module}' module  ..."
      for testSubDir in $( find . -type f -name "*.bats" | rev | sed -E "s|^([^/]+)/(.*)$|\2|" | rev ); do
        testName=$( echo "$testSubDir" | cut -d / -f 2,3 )
        echo " - Running test '${testName}' ..."
        (
          cd ${testName}
          testDir="${targetDir}/${module}/${testName}"
          mkdir -p ${testDir}
          processFiles "${testDir}" "${modulesPath}" "${modulePath}"

          if [ -f terraform-requirements ]; then
            for requirement in $(cat terraform-requirements)
            do
              cp ${modulesPath}/${requirement}/*.tf ${testDir}
              cp ${modulesPath}/${requirement}/*.json ${testDir} 2>/dev/null || :
            done
          fi

          fixturesDir="fixtures"
          if [ -d "${fixturesDir}" ]; then
            (
              cd ${fixturesDir}
              processFiles "${testDir}" "${modulesPath}" "${PWD}"
              cd ${testDir}
              processTerraformVars
              #exit 0; #TODO remove
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
              echo "${module}(${testName}):${testState}:${duration}" >> ${testResults}
            fi
          )
          # Stepping out of module
        )
      done
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
-m, --module; Run the specified modules separated by ','
-a, --all; Run all modules
-td, --terraform-destroy
" | column -t -s ";"
}

options=$(getopt -o h,d,m:,a,td --long help,debug,module:,all,terraform-destroy -n 'parse-options' -- "$@")

if [ $? != 0 ]; then
  echo "Failed parsing options." >&2
  exit 1
fi

while true; do
  case "$1" in
    -h  | --help) usage; exit;;
    -d  | --debug) set -eox pipefail; shift 1;;
    -m  | --module) modules=${2//,/ }; shift 2;;
    -a  | --all )
        modules=$( find ${modulesPath} -maxdepth 1 -type d | rev | cut -d / -f 1 | rev );
        shift 1
        ;;
    -td | --terraform-destroy) action=terraform-destroy; shift 1;;
    -- ) shift; break ;;
    "" ) break ;;
    * ) echo "Unknown option provided ${1}"; usage; exit 1; ;;
  esac
done

[ -f "${testResults}" ] && rm -f ${testResults}

echo "Testing modules:"
for module in ${modules}; do
    echo "  - ${module}"
done;

if [ "$action" = "terraform-destroy" ]; then
  for module in ${modules}
  do
    (
      cd ${targetDir}
      if [ -d "${module}" ]; then
        for moduleTestDir in $( find ${module} -type f -name "*.tfstate" | rev | sed -E "s|^([^/]+)/(.*)$|\2|" | rev );
        do
          (
            cd ${moduleTestDir};
            echo "Destroying '${module}' module  ..."
            terraform destroy -auto-approve
            fixturesDir="${moduleTestDir}/fixtures"
            if [ -d ${fixturesDir} ]; then
              (
                cd ${fixturesDir};
                terraform destroy -auto-approve
              )
            fi
          )
        done;
      fi
    )
  done
else

  for module in ${modules}; do
    testModule "${module}" "${modulesPath}/${module}" "${modulesPath}"
  done

  displayTestResults ${testResults}

fi
