function processFiles() {
  targetDir="$1"
  modulesPath="$2"
  modulePath="$3"
  
  if [ -f ${targetDir}/terraform.tfstate ]; then
    cd ${targetDir}
    terraform destroy -auto-approve -no-color
    cd -
  fi
  rm -rf ${targetDir} > /dev/null 2>&1
  mkdir ${targetDir}
  terraformVars=terraform.tfvars.json

  # Defaults
  cp ${modulesPath}/00-data.tf ${targetDir}
  cp ${modulesPath}/00-network-variables.tf ${targetDir}
  cp ${modulesPath}/00-provider-credentials.tf ${targetDir}
  cp ${modulesPath}/00-provider-credentials-variables.tf ${targetDir}

  # Data
  data="${modulesPath}/ec2/ec2-ubuntu-18.04.tf"
  cp ${data} ${targetDir}

  # Test
  cp ${basedir}/.test/terraform.bash ${targetDir}
  cp ${terraformVars} ${targetDir}
  cp terraform* ${targetDir}
  [ -f .noterraform ] && cp .noterraform ${targetDir}
  [ -f .nodestroy ] && cp .nodestroy ${targetDir}
  cp -r ${modulePath}/*.tf ${targetDir}
  # suppress the error message and exit code
  cp -r ${modulePath}/*.json ${targetDir} 2>/dev/null || :
}

function processTerraformVars() {
  # ------------------------------------------------------------------
  # AWS credentials processing
  # ------------------------------------------------------------------
  AWS_ACCESS_KEY_ID=$(${awsCredentialsScript} --profile=${awsProfile} --key)
  AWS_SECRET_ACCESS=$(${awsCredentialsScript} --profile=${awsProfile} --secret)
  sed -e "s|\$AWS_ACCESS_KEY_ID|$AWS_ACCESS_KEY_ID|;
  s|\$AWS_SECRET_ACCESS|$AWS_SECRET_ACCESS|;
  s|\$AWS_USER|$AWS_USER|;
  s|\$AWS_REGION|$AWS_REGION|" ${terraformVars} > tmp ; 
  mv tmp ${terraformVars}
}

function displayDuration() {
  duration="$1"
  if (( $duration > 3600 )) ; then
      let "hours=duration/3600"
      let "minutes=(duration%3600)/60"
      let "seconds=(duration%3600)%60"
      echo "${hours}h ${minutes}m ${seconds}s"
  elif (( $duration > 60 )) ; then
      let "minutes=(duration%3600)/60"
      let "seconds=(duration%3600)%60"
      echo "${minutes}m ${seconds}s"
  else
      echo "${duration}s"
  fi
}

function displayTestResults() {
  testResults="$1"
  # This block will ultimately go away when I figure out how to wrap all the terraform
  # logic in BATS functions, then all the Terraform operations will be logged in the
  # background and only the test results will appear.

  # Produces output like:
  #
  # Module ec2 ............... OK (2s)
  # Module id ................ OK (15s)
  # Module s3 ................ OK (10s)
  if [ -f "${testResults}" ]; then
    echo
    pad=$(printf '%0.1s' "."{1..70})
    padlength=20
    while IFS= read -r line
    do
      IFS=":" read -ra resultLine <<< "${line}"
      module="${resultLine[0]}"
      result="${resultLine[1]}"
      duration="$(displayDuration ${resultLine[2]})"
      if [ "${result}" = "OK" ]; then
        printf '\e[1;32m Module %s %*.*s %s (%s)\e[m\n' "$module" 0 $((padlength - ${#module} - ${#result} )) "$pad" "$result" "$duration"
      else
        printf '\e[1;31m Module %s %*.*s %s (%s)\e[m\n' "$module" 0 $((padlength - ${#module} - ${#result} )) "$pad" "$result" "$duration"
      fi
    done < "${testResults}"
    echo
  fi
}
