output "cluster_name" {
  description = "Kind cluster name."
  value       = kind_cluster.main.name
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig."
  value       = kind_cluster.main.kubeconfig_path
}

output "app_namespace" {
  description = "Namespace where the app is deployed."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "ingress_local_url" {
  description = "Local URL to reach the app via nginx ingress."
  value       = "http://localhost:8080  (add 'deploy-kit.local' to /etc/hosts if using hostname routing)"
}
