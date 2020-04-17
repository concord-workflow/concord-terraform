# These functions operate on the terraform-outputs.json that is generated
# by the test harness. We use 'jq' queries to retrieve values from the
# terraform-outputs.json

function terraformOutputValue() {
  cat terraform-outputs.json | jq -r "${1}" | tr -d "\r\t\n"
}

function assertTerraformOutputArraySize() {
  # $1: expected map size
  # $2: jq query pointing array
  value=$(cat terraform-outputs.json | jq "${2} | length" | tr -d "\r\t\n")
  [ "${value}" == "${1}" ]
}

function assertTerraformOutputMapSize() {
  # $1: expected map size
  # $2: jq query pointing map object
  value=$(cat terraform-outputs.json | jq -r "${2}" | jq keys | jq length  | tr -d "\r\t\n")
  [ "${value}" == "${1}" ]
}

function assertTerraformOutputEquals() {
  # $1: expected value
  # $2: jq query to extract value from terraform-outputs.json
  value=$(cat terraform-outputs.json | jq -r "${2}" | tr -d "\r\t\n")
  [[ "${value}" == "${1}" ]]
}

function assertTerraformOutputNotEmpty() {
  # $1: jq query to extract value from terraform-outputs.json
  value=$(cat terraform-outputs.json | jq -r "${1}" | tr -d "\r\t\n")
  [ ! -z "${value}" ]
}
