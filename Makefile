.DEFAULT_GOAL := help
IMAGE ?= myserver
TAG ?= v1.0

help: ## Подсказка по доступным командам
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

install-redos: ## Установка Docker на РедОС
	@dnf makecache
	@dnf install docker-ce docker-ce-cli docker-compose jq -y
	@systemctl enable --now docker

install-astra: ## Установка Docker на Astra Linux
	@apt-get update
	@apt install wget docker.io docker-compose jq -y
	@systemctl enable --now docker

install-rhel: ## Установка Docker для RHEL based дистрибутивов
	@yum install -y yum-utils
	@yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	@yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
	@systemctl enable --now docker

install-debian: ## Установка Docker для Debian based дистрибутивов
	@apt-get update
	@apt-get install ca-certificates curl
	@install -m 0755 -d /etc/apt/keyrings
	@curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	@chmod a+r /etc/apt/keyrings/docker.asc
	@echo \
  		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	@sudo apt-get update
	@apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	@systemctl enable --now docker

build: ## Сборка Go пакетов и Docker image, указать название образа и tag для image: IMAGE= TAG=
	@docker build -t ${IMAGE}:${TAG} .
	@sed -i "s/\(^.*image: \).*:v.*/\1${IMAGE}:${TAG}/2" docker-compose.yml

up: ## Запуск базы данных и сервера на основе docker-compose
	@docker compose up -d --build

down: ## Удаление базы данных и сервера на основе docker-compose
	@docker-compose down

dev-up: ## Запуск базы данных на основе docker-compose
	@docker-compose up -d --build db

dev-down: ## Удаление базы данных на основе docker-compose
	@docker-compose down db

logs-dev: ## Получить логи базы данных
	@docker-compose logs db
	@echo "Healthcheck status:"
	@docker inspect --format='{{json .State.Health}}' $(shell docker ps --format '{{.Names}}' -f name=db) | jq

logs: logs-dev ## Получить логи инсталляции
	@docker-compose logs server

test: ## Проверка работоспосбности инсталляции
	@echo "--- Container status ---"
	@docker ps --format "{{.Names}}: {{.Status}}"
	@echo "--- Port readiness ---"
	@printf 'GET / HTTP/1.1\n\n' > /dev/tcp/127.0.0.1/58080 > /dev/null 2>&1 && echo "Port 58080 is open" || echo "Port 58080 is closed"
	@wget -T5 --spider http://127.0.0.1:58080 > /dev/null 2>&1 && echo "Port 58080 not empty" || echo "Port 58080 is empty"
	
.PHONY: up down dev-up dev-down build test logs-dev logs install-astra install-debian install-redos install-rhel