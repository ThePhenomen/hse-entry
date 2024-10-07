.DEFAULT_GOAL := help
IMAGE ?= myserver
TAG ?= v1.0

help: ## Подсказка по доступным командам
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

install: ## Установка Docker
	@dnf install wget docker-ce docker-ce-cli docker-compose jq -y || apt install wget docker.io docker-compose jq -y
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

logs: logs-dev## Получить логи инсталляции
	@docker-compose logs server

.PHONY: up down dev-up dev-down build install logs-dev logs