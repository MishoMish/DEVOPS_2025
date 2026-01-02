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
  default     = "ghcr.io/mishomish/api-service:latest"
}

variable "web_image" {
  description = "Web service Docker image"
  type        = string
  default     = "ghcr.io/mishomish/web-service:latest"
}

# Database variables
variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "devopsdb"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "devops"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "devops123"
  sensitive   = true
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
      "requests.memory" = "4Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "6Gi"
      "pods"            = "15"
      "persistentvolumeclaims" = "3"
    }
  }
}

# PostgreSQL Secret
resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
    labels = {
      app        = "postgres"
      managed-by = "terraform"
    }
  }

  data = {
    POSTGRES_DB       = var.postgres_db
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
  }

  type = "Opaque"
}

# PostgreSQL ConfigMap
resource "kubernetes_config_map" "postgres_config" {
  metadata {
    name      = "postgres-config"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
    labels = {
      app        = "postgres"
      managed-by = "terraform"
    }
  }

  data = {
    PGDATA = "/var/lib/postgresql/data/pgdata"
  }
}

# Database Network Policy - Allow API to connect to PostgreSQL
resource "kubernetes_network_policy" "postgres_network_policy" {
  metadata {
    name      = "postgres-network-policy"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "postgres"
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "api-service"
          }
        }
      }

      from {
        pod_selector {
          match_labels = {
            app = "flyway"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
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

    egress {
      to {
        pod_selector {
          match_labels = {
            app = "postgres"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

# LimitRange for namespace (ensures all pods have resource constraints)
resource "kubernetes_limit_range" "devops_demo_limits" {
  metadata {
    name      = "devops-demo-limits"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "200m"
        memory = "256Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
      max = {
        cpu    = "1"
        memory = "512Mi"
      }
      min = {
        cpu    = "50m"
        memory = "32Mi"
      }
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
    labels = {
      app        = "devops-demo"
      managed-by = "terraform"
    }
  }

  data = {
    NODE_ENV     = "production"
    LOG_LEVEL    = "info"
    API_PORT     = "3000"
    WEB_PORT     = "80"
    DB_HOST      = "postgres"
    DB_PORT      = "5432"
  }
}

# Network Policy for web service (allow ingress traffic)
resource "kubernetes_network_policy" "web_ingress_policy" {
  metadata {
    name      = "web-ingress-policy"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "web-service"
      }
    }

    ingress {
      from {
        namespace_selector {}  # Allow from ingress controller
      }

      ports {
        port     = "80"
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

output "resource_quota" {
  description = "Resource quota applied to namespace"
  value = {
    cpu_requests    = kubernetes_resource_quota.devops_demo_quota.spec[0].hard["requests.cpu"]
    memory_requests = kubernetes_resource_quota.devops_demo_quota.spec[0].hard["requests.memory"]
    cpu_limits      = kubernetes_resource_quota.devops_demo_quota.spec[0].hard["limits.cpu"]
    memory_limits   = kubernetes_resource_quota.devops_demo_quota.spec[0].hard["limits.memory"]
    max_pods        = kubernetes_resource_quota.devops_demo_quota.spec[0].hard["pods"]
  }
}

output "config_map_name" {
  description = "Name of the application ConfigMap"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "postgres_secret_name" {
  description = "Name of the PostgreSQL secret"
  value       = kubernetes_secret.postgres_secret.metadata[0].name
}
