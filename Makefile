# Platform shortcuts 
# Requires: gcloud, terraform, kubectl, helm (see docs/onboarding/runbook.md)

TF_BOOTSTRAP      := infra/terraform/envs/bootstrap
TF_FOUNDATION := infra/terraform/envs/foundation
TF_OBSERVABILITY := infra/terraform/envs/observability
CHARTS        := \
	charts/microservices/adservice \
	charts/microservices/cartservice \
	charts/microservices/checkoutservice \
	charts/microservices/currencyservice \
	charts/microservices/emailservice \
	charts/microservices/frontend \
	charts/microservices/loadgenerator \
	charts/microservices/paymentservice \
	charts/microservices/productcatalogservice \
	charts/microservices/recommendationservice \
	charts/microservices/shippingservice
GCP_REGION    ?= us-central1

.PHONY: help fmt validate helm-lint tf-bootstrap-init tf-bootstrap-plan tf-foundation-init tf-foundation-plan tf-observability-init tf-observability-plan kubeconfig smoke slo-probe

help:
	@echo "Targets:"
	@echo "  fmt                    - terraform fmt -recursive"
	@echo "  validate               - terraform validate (bootstrap + foundation, no backend)"
	@echo "  helm-lint              - helm lint all microservice charts"
	@echo "  tf-bootstrap-init      - init bootstrap stack"
	@echo "  tf-bootstrap-plan      - plan bootstrap"
	@echo "  tf-foundation-init     - init foundation stack"
	@echo "  tf-foundation-plan     - plan foundation"
	@echo "  tf-observability-init  - init observability stack (SLOs, alerts)"
	@echo "  tf-observability-plan  - plan observability"
	@echo "  kubeconfig             - gcloud get-credentials from foundation outputs"
	@echo "  smoke                  - HTTP smoke test (URL via SMOKE_URL)"
	@echo "  slo-probe              - SLO synthetic probe (URL via SLO_URL)"

fmt:
	terraform -chdir=$(TF_BOOTSTRAP) fmt -recursive
	terraform -chdir=$(TF_FOUNDATION) fmt -recursive
	terraform -chdir=$(TF_OBSERVABILITY) fmt -recursive
	terraform -chdir=infra/terraform/modules fmt -recursive 2>/dev/null || true

validate:
	terraform -chdir=$(TF_BOOTSTRAP) init -backend=false -input=false
	terraform -chdir=$(TF_BOOTSTRAP) validate
	terraform -chdir=$(TF_FOUNDATION) init -backend=false -input=false
	terraform -chdir=$(TF_FOUNDATION) validate
	terraform -chdir=$(TF_OBSERVABILITY) init -backend=false -input=false
	terraform -chdir=$(TF_OBSERVABILITY) validate

helm-lint:
	@for c in $(CHARTS); do echo "==> Linting $$c"; helm lint $$c; done

tf-bootstrap-init:
	terraform -chdir=$(TF_BOOTSTRAP) init

tf-bootstrap-plan:
	terraform -chdir=$(TF_BOOTSTRAP) plan

tf-foundation-init:
	terraform -chdir=$(TF_FOUNDATION) init

tf-foundation-plan:
	terraform -chdir=$(TF_FOUNDATION) plan

tf-observability-init:
	terraform -chdir=$(TF_OBSERVABILITY) init

tf-observability-plan:
	terraform -chdir=$(TF_OBSERVABILITY) plan

kubeconfig:
	gcloud container clusters get-credentials \
		"$$(terraform -chdir=$(TF_FOUNDATION) output -raw cluster_name)" \
		--region "$(GCP_REGION)" \
		--project "$$(terraform -chdir=$(TF_FOUNDATION) output -raw project_id)"

smoke:
	bash scripts/smoke.sh "$(or $(SMOKE_URL),https://dev.tanyadominicsheytech.eu)"

slo-probe:
	bash scripts/slo-probe.sh "$(or $(SLO_URL),https://tanyadominicsheytech.eu)"