# TODO

- Create a common way to use data resources: the 00-data.tf is used by several of the modules except for the vpc module, not sure if we live with this exception and remove it from being used in the vpc module or let each module state it's data requirement for a vpc
- The duration doesn't take into account the fixture setup time
- Add support for post hooks: provision and ec2 compute with a root volume set to delete on compute termination. We gather the volume id during the test and then after the compute is terminated make sure the volume has been deleted
- Try to use the BATS method for pre/post hooks instead of the custom mechanism used here
- Integrate bats-assert
- For the whole test suite it would be safest to create a VPC to run all the tests in and then destroy the VPC
- Make each module self-contained and don't rely on the shared 00-data.tf, some modules need it and some don't which is too complicated
- Tag all resources in a known way to make querying and filtering easier
- Make the rds-postgres module make instances in private subnets, and for testing create an SG with a public subnet for access to test connectivity 
