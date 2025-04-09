SHELL := /bin/bash
ROOT_DIR := $(shell pwd)

help: ## This help.
	@bash scripts/welcome.sh
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>...\033[0m\n"} /^[[:alnum:]_.-]+:.*?##/ { printf "  \033[36m%-20s\033[0m  %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL: help

##@ Command

.PHONY: limit
limit: ## 获取配置文件中的cpu和内存限额情况
	@./scripts/get_config_limit.sh

.PHONY: load
load: ## 加载images目录下的镜像.
	@./scripts/load_images.sh

.PHONY: install
install: ## 进行一键安装
	@./scripts/preflight.sh
	@./scripts/install.sh


.PHONY: install.%
install.%: ## 安装指定的目录
	$(eval bin := $(word 1,$(subst ., ,$*)))
	@./install/install_$(bin).sh
	@cd artifact/$(bin) && ./start.sh

.PHONY: conf.%
conf.%: ## 安装指定的目录
	$(eval bin := $(word 1,$(subst ., ,$*)))
	@./scripts/conf.sh $(bin)

.PHONY: uninstall
uninstall: ## 进行一键卸载
	@./scripts/uninstall.sh