.DEFAULT_GOAL := help

GITCOMMIT            := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES  := $(shell git status --porcelain --untracked-files=no)
ORG                  ?= joshmyers

ifneq ($(GITUNTRACKEDCHANGES),)
GITCOMMIT            := $(GITCOMMIT)-dirty
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: check_docker
check_docker:
	@$(if $(shell which docker),,$(error Please ensure Docker is installed in $PATH))

.PHONY: preflight_checks
preflight_checks: check_docker

.PHONY: all
all: build_pixiecore build_waitron run_pixiecore run_waitron ## Run all the things!

.PHONY: build_pixiecore
build_pixiecore: preflight_checks ## Build Pixiecore Docker container
	@eval $$(minikube docker-env) ; \
	echo "==> Building container..." ; \
	docker build -t "$(ORG)/pixiecore:$(GITCOMMIT)" -f dockerfiles/pixiecore .

.PHONY: build_waitron
build_waitron: preflight_checks ## Build Waitron Docker container
	@eval $$(minikube docker-env) ; \
	echo "==> Building container..." ; \
	$(call build_docker,waitron)

.PHONY: run_pixiecore
run_pixiecore: preflight_checks ## Run Pixiecore
	@echo "==> Running app Pixiecore:$(GITCOMMIT)"
	@docker run \
	  --net=host -p 67/udp $(ORG)/pixiecore api http://localhost:9090 -d

.PHONY: mount_data_into_minikube
mount_data_into_minikube: ## Mount PWD into Minikube VirtualMachine
	$(shell minikube mount $(PWD):/data)

.PHONY: run_waitron
run_waitron: preflight_checks ## Run Waitron
	@echo "==> Running app Waitron:$(GITCOMMIT)"
	@docker run --net=host -v $(PWD):/data -e CONFIG_FILE=/data/config.yaml $(ORG)/waitron
