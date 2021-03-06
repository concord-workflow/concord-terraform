load terraform
load variables

@test "Validate outputs of Terraform 'eks-roles-policies' module" {
  assertTerraformOutputNotEmpty ".vpc_id.value"
  assertTerraformOutputEquals $NAME ".vpc.value.tags.Name"
  assertTerraformOutputNotEmpty '.["nat-eips"].value["us-east-2a"].id'
  assertTerraformOutputNotEmpty '.["nat-gw"].value["us-east-2a"].id'
  assertTerraformOutputNotEmpty '.["public_subnets"].value["us-east-2a"].id'
  assertTerraformOutputNotEmpty '.["privat_subnets"].value["us-east-2a"].id'
  assertTerraformOutputNotEmpty '.["eks-service-role"].value.arn'
  assertTerraformOutputEquals "$NAME-eks-service-node-role" '.["eks-service-role"].value.id'
  assertTerraformOutputNotEmpty '.["eks-worker-node-instance-profile"].value.arn'
  assertTerraformOutputEquals "$NAME-eks-worker-node-profile" '.["eks-worker-node-instance-profile"].value.id'
  assertTerraformOutputNotEmpty '.["eks-worker-node-role"].value.arn'
  assertTerraformOutputEquals "$NAME-eks-worker-node-role" '.["eks-worker-node-role"].value.id'
  assertTerraformOutputNotEmpty '.["iam-role"].value.arn'
  assertTerraformOutputEquals $NAME '.["iam-role"].value.id'
  assertTerraformOutputNotEmpty '.["instance-profile"].value.arn'
  assertTerraformOutputEquals $NAME '.["instance-profile"].value.id'
}
