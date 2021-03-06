load terraform
load variables

@test "Validate outputs of Terraform 'dynamodb' module" {
  assertTerraformOutputEquals $NAME ".dynamodb_table.value.id"
  assertTerraformOutputNotEmpty ".dynamodb_table.value.arn"
  assertTerraformOutputEquals "LockID" ".dynamodb_table.value.hash_key"
  assertTerraformOutputEquals "20" ".dynamodb_table.value.read_capacity"
  assertTerraformOutputEquals "20" ".dynamodb_table.value.write_capacity"
}
