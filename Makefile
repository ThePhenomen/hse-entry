.DEFAULT_GOAL := help
IMAGE ?= myserver
TAG ?= v1.0

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

install: ## Установка Docker, Go и пакета lib/pq
	@dnf install wget docker-ce docker-ce-cli docker-compose -y || apt install wget docker.io docker-compose -y
	@rm -f go1.23.2.linux-amd64.tar.gz || echo Already clean!
	@wget https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
	@rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
	@export PATH=${PATH}:/usr/local/go/bin
	@go get -u github.com/lib/pq || echo Package is already installed!

build: ## Сборка Go пакетов и Docker image, указать название образа и tag для image: IMAGE= TAG=
	@CGO_ENABLED=0 go build ./ || echo Project is already built!
	@docker build -t ${IMAGE}:${TAG} . || echo Docker image already exists!

up: install build ## Запуск базы данных и сервера на основе docker-compose
	@docker compose up -d --build

down: ## Удаление базы данных и сервера на основе docker-compose
	@docker-compose down

dev-up: ## Запуск базы данных на основе docker-compose
	@docker-compose up -d --build db

dev-down: ## Удаление базы данных на основе docker-compose
	@docker-compose down db

.PHONY: up down dev-up dev-down build install