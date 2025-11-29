# DevOps Demo - Terraform Outputs

output "deployment_info" {
  description = "Information about the deployment"
  value = {
    namespace = var.namespace
    api_image = var.api_image
    web_image = var.web_image
  }
}

output "next_steps" {
  description = "Next steps after Terraform apply"
  value = <<-EOT
    
    ✅ Terraform has created the namespace and basic resources.
    
    Next steps:
    1. Apply Kubernetes manifests:
       kubectl apply -f k8s/
    
    2. Check deployment status:
       kubectl get all -n ${var.namespace}
    
    3. Access the application (after setting up ingress):
       Add to /etc/hosts: <INGRESS_IP> devops-demo.local
       Then visit: http://devops-demo.local
    
  EOT
}
