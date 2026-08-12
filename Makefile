.PHONY: up down deploy lint lint-tf lint-helm lint-kustomize lint-yaml \
        build-app kustomize-build argocd-install help

CLUSTER_NAME   ?= deploy-kit
APP_IMAGE_TAG  ?= latest
TF_DIR         := terraform
CHART_DIR      := charts/deploy-kit-app
K8S_BASE       := k8s/base
K8S_DEV        := k8s/overlays/dev
K8S_PROD       := k8s/overlays/prod

## up — create kind cluster + terraform apply (full stack)
up:
	terraform -chdir=$(TF_DIR) init
	terraform -chdir=$(TF_DIR) apply -auto-approve

## down — destroy kind cluster + terraform state
down:
	terraform -chdir=$(TF_DIR) destroy -auto-approve

## deploy — kustomize apply dev overlay directly (no terraform)
deploy: kubectl-ctx
	kubectl apply -k $(K8S_DEV)

## kustomize-build — render all overlays to stdout (no cluster needed)
kustomize-build:
	@echo "=== base ===" && kubectl kustomize $(K8S_BASE)
	@echo "=== dev ===" && kubectl kustomize $(K8S_DEV)
	@echo "=== prod ===" && kubectl kustomize $(K8S_PROD)

## lint — run all linters
lint: lint-tf lint-helm lint-kustomize lint-yaml

## lint-tf — terraform fmt + validate
lint-tf:
	terraform -chdir=$(TF_DIR) init -backend=false
	terraform -chdir=$(TF_DIR) fmt -check -recursive
	terraform -chdir=$(TF_DIR) validate

## lint-helm — helm lint
lint-helm:
	helm lint $(CHART_DIR)

## lint-kustomize — kustomize build (renders without applying)
lint-kustomize:
	kubectl kustomize $(K8S_BASE) > /dev/null
	kubectl kustomize $(K8S_DEV) > /dev/null
	kubectl kustomize $(K8S_PROD) > /dev/null

## lint-yaml — yamllint on all manifests
lint-yaml:
	yamllint -d '{extends: relaxed, rules: {line-length: {max: 120}}}' \
		k8s/ charts/ gitops/ observability/

## build-app — build docker image locally
build-app:
	docker build -t ghcr.io/chirag127/deploy-kit-app:$(APP_IMAGE_TAG) app/

## load-image — load docker image into kind cluster
load-image: build-app
	kind load docker-image ghcr.io/chirag127/deploy-kit-app:$(APP_IMAGE_TAG) \
		--name $(CLUSTER_NAME)

## argocd-install — install Argo CD + apply Application manifest
argocd-install:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd \
		-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server \
		-n argocd --timeout=120s
	kubectl apply -f gitops/argocd-application.yaml

## kubectl-ctx — print current kubectl context
kubectl-ctx:
	@kubectl config current-context

## help — list targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'
