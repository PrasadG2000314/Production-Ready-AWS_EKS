# 1. AWS නෙට්වර්ක් එක (VPC) හැදීම
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-gitops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    "kubernetes.io/cluster/gitops-eks-cluster" = "shared"
  }
}

# 2. Amazon EKS (Kubernetes) Cluster එක හැදීම
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "gitops-eks-cluster"
  cluster_version = "1.30"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # සර්වර්ස් (Worker Nodes) හැදීම
  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"] # ArgoCD run වෙන්න t3.medium එකක්වත් ඕනේ වෙනවා
      ami_type       = "AL2023_x86_64_STANDARD"
    }
  }

  enable_cluster_creator_admin_permissions = true
}

