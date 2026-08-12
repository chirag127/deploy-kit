# ── kind cluster ─────────────────────────────────────────────────────────────
variable "cluster_name" {
  description = "Name of the kind cluster."
  type        = string
  default     = "deploy-kit"
}

variable "cluster_k8s_version" {
  description = "Kubernetes image tag for the kind node."
  type        = string
  default     = "v1.32.0"
}

# ── nginx-ingress ─────────────────────────────────────────────────────────────
variable "ingress_nginx_chart_version" {
  description = "Helm chart version for ingress-nginx."
  type        = string
  default     = "4.12.3"
}

# ── kube-prometheus-stack ─────────────────────────────────────────────────────
variable "monitoring_enabled" {
  description = "Install kube-prometheus-stack (Prometheus + Grafana)."
  type        = bool
  default     = true
}

variable "kube_prometheus_stack_chart_version" {
  description = "Helm chart version for kube-prometheus-stack."
  type        = string
  default     = "72.6.3"
}

# ── app ───────────────────────────────────────────────────────────────────────
variable "app_chart_path" {
  description = "Path to the local Helm chart for deploy-kit-app."
  type        = string
  default     = "../charts/deploy-kit-app"
}

variable "app_image_tag" {
  description = "Image tag for deploy-kit-app."
  type        = string
  default     = "latest"
}

variable "app_namespace" {
  description = "Kubernetes namespace for deploy-kit-app."
  type        = string
  default     = "deploy-kit"
}
