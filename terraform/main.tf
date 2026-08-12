# ── kind cluster ─────────────────────────────────────────────────────────────
resource "kind_cluster" "main" {
  name           = var.cluster_name
  node_image     = "kindest/node:${var.cluster_k8s_version}"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      # Extra port mappings so the nginx ingress is reachable on localhost
      extra_port_mappings {
        container_port = 80
        host_port      = 8080
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 8443
        protocol       = "TCP"
      }
      # Label required by nginx ingress DaemonSet nodeSelector
      labels = {
        "ingress-ready" = "true"
      }
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

# ── provider configuration (derived from kind output) ─────────────────────────
provider "kubernetes" {
  host                   = kind_cluster.main.endpoint
  cluster_ca_certificate = base64decode(kind_cluster.main.cluster_ca_certificate)
  client_certificate     = base64decode(kind_cluster.main.client_certificate)
  client_key             = base64decode(kind_cluster.main.client_key)
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.main.endpoint
    cluster_ca_certificate = base64decode(kind_cluster.main.cluster_ca_certificate)
    client_certificate     = base64decode(kind_cluster.main.client_certificate)
    client_key             = base64decode(kind_cluster.main.client_key)
  }
}

# ── namespaces ────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [kind_cluster.main]
}

resource "kubernetes_namespace" "monitoring" {
  count = var.monitoring_enabled ? 1 : 0

  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "kubernetes.io/metadata.name"  = "monitoring"
    }
  }

  depends_on = [kind_cluster.main]
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "kubernetes.io/metadata.name"  = "ingress-nginx"
    }
  }

  depends_on = [kind_cluster.main]
}

# ── nginx ingress ─────────────────────────────────────────────────────────────
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    yamlencode({
      controller = {
        hostPort = {
          enabled = true
        }
        nodeSelector = {
          "ingress-ready" = "true"
        }
        tolerations = [
          {
            key      = "node-role.kubernetes.io/control-plane"
            operator = "Equal"
            effect   = "NoSchedule"
          }
        ]
        service = {
          type = "NodePort"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]
}

# ── kube-prometheus-stack ─────────────────────────────────────────────────────
resource "helm_release" "kube_prometheus_stack" {
  count = var.monitoring_enabled ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_chart_version
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  timeout = 600

  values = [file("${path.module}/values/kube-prometheus-stack.yaml")]

  depends_on = [kubernetes_namespace.monitoring]
}

# ── deploy-kit-app ────────────────────────────────────────────────────────────
resource "helm_release" "app" {
  name      = "deploy-kit-app"
  chart     = var.app_chart_path
  namespace = kubernetes_namespace.app.metadata[0].name

  values = [
    yamlencode({
      image = {
        tag = var.app_image_tag
      }
      config = {
        ENV = "kind"
      }
    })
  ]

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.kube_prometheus_stack,
  ]
}
