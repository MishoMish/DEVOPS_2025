# Terraform Configuration for DevOps Demo Project
# This configuration sets up the basic Kubernetes namespace and resources

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Configure Kubernetes Provider
# For local development with minikube, use: kubectl config view --minify --flatten
# For AKS, configure using Azure CLI or service principal
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

# Variables
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "minikube"  # Change to your context name
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "devops-demo"
}

variable "api_image" {
  description = "API service Docker image"
  type        = string
  default     = "ghcr.io/YOUR_GITHUB_USERNAME/api-service:latest"
}

variable "web_image" {
  description = "Web service Docker image"
  type        = string
  default     = "ghcr.io/YOUR_GITHUB_USERNAME/web-service:latest"
}

# Create Namespace
resource "kubernetes_namespace" "devops_demo" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = "production"
      managed-by  = "terraform"
    }
  }
}

# Optional: Create Image Pull Secret for GitHub Container Registry
# Uncomment and configure if using private repositories
# resource "kubernetes_secret" "ghcr_secret" {
#   metadata {
#     name      = "ghcr-secret"
#     namespace = kubernetes_namespace.devops_demo.metadata[0].name
#   }
#
#   type = "kubernetes.io/dockerconfigjson"
#
#   data = {
#     ".dockerconfigjson" = jsonencode({
#       auths = {
#         "ghcr.io" = {
#           username = var.github_username
#           password = var.github_token
#           email    = var.github_email
#           auth     = base64encode("${var.github_username}:${var.github_token}")
#         }
#       }
#     })
#   }
# }

# Optional: Resource Quota for the namespace
resource "kubernetes_resource_quota" "devops_demo_quota" {
  metadata {
    name      = "devops-demo-quota"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "10"
    }
  }
}

# Optional: Network Policy (if your cluster supports it)
resource "kubernetes_network_policy" "devops_demo_network_policy" {
  metadata {
    name      = "devops-demo-network-policy"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "api-service"
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "web-service"
          }
        }
      }

      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# Outputs
output "namespace_name" {
  description = "The name of the created namespace"
  value       = kubernetes_namespace.devops_demo.metadata[0].name
}

output "namespace_uid" {
  description = "The UID of the created namespace"
  value       = kubernetes_namespace.devops_demo.metadata[0].uid
}
