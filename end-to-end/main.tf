module "aws_vpc" {
    source = "../vpc"
    mvpc_cidr      = var.vpc_cidr
    mvpc_instance_tenancy = var.vpc_instance_tenancy
    mpublic_cidr = var.public_cidr
    mprivate_cidr = var.private_cidr
}

module "tomcat" {
  source = "../tomcat"
  depends_on = [
    module.aws_vpc
  ]
  mvpc_id = module.aws_vpc.vpc_id
  minstance_type = var.instance_type
  mpublic_subnet = module.aws_vpc.public_subnet
  mkey_name = var.key_name
}

module "sonarqube" {
  source = "../sonarqube"
  depends_on = [
    module.aws_vpc
  ]
  mvpc_id = module.aws_vpc.vpc_id
  sonar_instance_type = var.sonar_instance_type
  mpublic_subnet = module.aws_vpc.public_subnet
  mkey_name = var.key_name
}

module "jenkins" {
  source = "../jenkins"
   depends_on = [
    module.aws_vpc
  ]
  mvpc_id = module.aws_vpc.vpc_id
  minstance_type = var.instance_type
  mpublic_subnet = module.aws_vpc.public_subnet
  mkey_name = var.key_name
}
module "alb" {
  source = "../alb"
   depends_on = [
    module.aws_vpc
  ]
  mvpc_id = module.aws_vpc.vpc_id
  alb_subnets = [module.aws_vpc.public_subnet, module.aws_vpc.public_subnet1]
  tomcat_instance_id = module.tomcat.tomcat_instance
  jenkins_instance_id = module.jenkins.cicd_instance
  sonarqube_instance_id = module.sonarqube.sonarqube_instance
}