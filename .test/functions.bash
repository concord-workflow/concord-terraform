function processFiles() {
  terraformDir="$1"
  modulesPath="$2"
  modulePath="$3"

  rm -rf ${terraformDir} > /dev/null 2>&1
  mkdir ${terraformDir}
  terraformVars=terraform.tfvars.json

  # Defaults
  cp ${modulesPath}/00-data.tf ${terraformDir}
  cp ${modulesPath}/00-network-variables.tf ${terraformDir}
  cp ${modulesPath}/00-provider-credentials.tf ${terraformDir}
  cp ${modulesPath}/00-provider-credentials-variables.tf ${terraformDir}

  # Data
  data="${modulesPath}/ec2/ec2-ubuntu-18.04.tf"
  cp ${data} ${terraformDir}

  # Test
  cp ${basedir}/.test/terraform.bash ${terraformDir}
  cp ${terraformVars} ${terraformDir}
  cp terraform* ${terraformDir}
  [ -f .noterraform ] && cp .noterraform ${terraformDir}
  [ -f .nodestroy ] && cp .nodestroy ${terraformDir}
  cp -r ${modulePath}/*.tf ${terraformDir}
  # suppress the error message and exit code
  cp -r ${modulePath}/*.json ${terraformDir} 2>/dev/null || :
}

function processTerraformVars() {
  # ------------------------------------------------------------------
  # AWS credentials processing
  # ------------------------------------------------------------------
  AWS_ACCESS_KEY_ID=$(${awsCredentials} --profile=${awsProfile} --key)
  AWS_SECRET_ACCESS=$(${awsCredentials} --profile=${awsProfile} --secret)
  sed -e "s@\$AWS_ACCESS_KEY_ID@$AWS_ACCESS_KEY_ID@" ${terraformVars} | \
  sed -e "s@\$AWS_SECRET_ACCESS@$AWS_SECRET_ACCESS@" | \
  sed -e "s@\$AWS_USER@$AWS_USER@" | \
  sed -e "s@\$AWS_REGION@$AWS_REGION@" | \
  sed -e "s@\$AWS_KEYPAIR@$AWS_KEYPAIR@" > tmp ; mv tmp ${terraformVars}
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
