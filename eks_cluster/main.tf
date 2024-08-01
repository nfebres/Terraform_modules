# Create EKS cluster

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.22"

  vpc_id          = aws_vpc.main.id
  subnet_ids      = aws_subnet.private.*.id

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 50
    instance_types         = ["m5.large", "m6i.large", "m5n.large"] # Replace with your desired instance types
  }

  eks_managed_node_groups = {
    general = {
      desired_size = 3
      min_size     = 3
      max_size     = 6

      instance_types = ["m5.large", "m6i.large", "m5n.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
}


# Install Calico for networking

resource "kubernetes_calico" "calico" {
  depends_on = [module.eks]

  metadata {
    name = "calico"
  }

  spec {
    # Configuration options go here
  }
}


# Install Istio for service mesh

resource "kubernetes_namespace" "istio_namespace" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.14.1"
  namespace  = kubernetes_namespace.istio_namespace.metadata.0.name

  set {
    name  = "values.global.proxy.privileged"
    value = "true"
  }
}

