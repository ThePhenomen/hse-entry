### Список сокращений
- ОС - операционная система;
- ВМ - виртуальная машина;
- ПО - программное обеспечение;
- СУБД - система управления базами данных;
- DNS - Domain name server - доменная система имен;
- IaC - Infrastructure as Code - подход, позволяющий описывать инфраструктуру с помощью кода;
- FQDN - Fully Qualified Domain Name - полное доменное имя сервера.

### Методика развертывания инфраструктуры
Для развертывания веб-сервера с СУБД Postgresql необходимо выполнить следующие действия:
1. Создать ВМ в подходящей среде виртуализации. Я использовал систему виртуализации zVirt (доработанная версия oVirt), где развернул ВМ с ОС РедОС. Для автоматизации и ускорения развертывания ВМ возможно использовать ПО Terraform, реализующее подход IaC. Для работы с zVirt возможно использовать oVirt провайдер для Terraform. В этом случае для развертывания ВМ необходимо выполнить следующие действия:
    - В зависимости от дистрибутива (Debian based или RHEL based) выполнить одну из следующих команд соответственно для установки недостающих пакетов:
        ```
        sudo apt-get --assume-yes install gcc libxml2-dev python3-dev
        sudo dnf install -y gcc libxml2-devel python3-devel
        ```
    - Установить требуемые пакеты, выполнив следующую команду:
        ```
        pip3 install -r requirements.txt
        ```
    -  Экспортировать переменные окружения для доступа к zVirt, выполнив следующие команды:
        ```
        export TF_VAR_username=<username>@internal
        export TF_VAR_password=<password>
        ```
    - Получить ID Vnic нужной сети, выполнив следующую команду:
        ```
        eval '$(python3 get_vnic_id.py *vnic_ovirt_name*)'
        ```
    - Задать в файле "terraform.tfvars" переменные для создаваемой машины (описание каждой переменной находится в файле "variabled.tf"). Важно: переменные username и password являются чувствительной информацией, не рекомендуется их задавать в файле "terraform.tfvars".
    - Запустить создание виртуальной машины, выполнив следующую команду:
        ```
        terraform apply -auto-approve
        ```

2. Установить Docker и docker-compose, запустить службу docker.
    - Для РедОС необходимо выполнить следующую команду:
        ```
        sudo dnf makecache
        sudo dnf install docker-ce docker-ce-cli docker-compose -y
        ```
    - Для Astra Linux необходимо выполнить следующую команду:
        ```
        sudo apt-get update
        sudo apt-get install docker.io docker-compose -y
        ```
    - Для прочих Debian based дистрибутивов необходимо выполнить следующие команды:
        ```
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
             $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
         sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        ```
    - Для прочих RHEL based дистрибутивов необходимо выполнить следующие команды:
        ```
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ```
    - Для запуска службы docker и добавления ее в автозагрузку необходимо выполнить следующую команду:
        ```
        sudo systemctl enable --now docker
        ```

3. Произвести сборку Docker образа, выполнив следующую команду:
    ```
    docker build -t myserver:v0.0 .
    ```
    , где вместо myserver:v0.0 задать необходимое название образа и присвоить ему необходимый тэг.

4. Отредактировать файл docker-compose.yml, изменив, при необходимости, следующие строки:
    - db.image - образ для СУБД Postgresql, задать необходимую версию и тэг;
    - db.shm_size - размер параметра shared buffers, влияет на размер буфера, используемого для временного хранения данных;
    - db.environment.POSTGRES_DB - указать базу данных, которая будет инициализирована при создании контейнера;  
    - db.environment.POSTGRES_HOST_AUTH_METHOD - метод авторизации, используемый в Postgresql (по умолчанию trust); 
    - healthcheck - указать команду для проверки состояния базы данных, частоту, таймаут, количество повторных попыток для этого процесса, а так же период, через который начнется первая проверка (если этот параметр задать слишком маленьким, то база данных будет не успевать инициализироваться до момента начала healthcheck, что может мешать запуску контейнера);
    - volumes - задать тома для монтирования в контейнер, которые помогут сохранить данные базы данных при падении/перезапуске контейнера;
    - server.image - образ веб-сервера, который был собран на этапе 2;
    - server.ports - настроить проброс порта из контейнера на ВМ (данный веб-сервер слушает на 58080 порту) в формате "58080:*vm_port*". Данная настройка необходима, чтобы иметь возможность подключиться к серверу за пределами контейнера.

    *При необходимости отредактировать файл "init-user-db.sh", дополнив или изменив его SQL запросы, которые будут выполнены при создании контейнера с СУБД Postgresql.

5. Создать файлы ".env", "db_passwd.txt", "db_user.txt". В первый файл поместить следующие данные:
    - POSTGRES_HOST - хост, на котором развернута база данных. В данном случае указать "db";
    - POSTGRES_USER - пользователь, который будет использовать для подключения к базе данных и будет иметь права на создание, редактирование, удаление таблиц в выбранной базе данных;
    - POSTGRES_PASSWORD - пароль для пользователя POSTGRES_USER;
    - POSTGRES_DB - база данных для подключения.
    В файлах "db_passwd.txt" и "db_user.txt" указать пароль и имя пользователя соответственно, которые будут созданы в базе данных при разветывании (данные значения должны совпадать с POSTGRES_PASSWORD и POSTGRES_USER).

6. Настроить firewall, чтобы разрешить доступ к требуемому порту на ВМ из локальной сети. 
    - При использовании Debian based дистрибутивов необходимо выполнить следующую команду:
        ```
        sudo ufw allow <vm_port>/tcp
        sudo ufw allow from <net_ip>/<net_mask>
        sudo ufw enable
        ```
    - При использовании RHEL based дистрибутивов необходимо выполнить следующую команду:
        ```
        sudo systemctl enable --now firewalld 
        sudo firewall-cmd --permanent --add-port=<vm_port>/tcp
        sudo  firewall-cmd --permanent --add-source=<net_ip>/<net_mask>
        sudo firewall-cmd --reload
        ```

7. Запустить создание инфраструктуры, выполнив следующую команду:
    ```
    docker-compose up -d --build
    ```
    Если требуется создать только базу данных, необходимо выполнить следующую команду:
    ```
    docker-compose up -d db
    ```

8. Проверить статус запущенных контейнеров, выполнив следующую команду:
    ```
    docker ps
    ```
    Для получения логов необходимо выполнить следующую команду:
    ```
    docker-compose logs
    ```
    Для получения логов для конкретной службы необходимо выполнить следующую команду:
    ```
    docker-compose logs db (или server)
    ```

### Использование Makefile и утилиты make
make - утилита, предназначенная для автоматизации рутинных действий на основе правил, описанных в Makefile. 
Для установки make на Debian based дистрибутивы необходимо выполнить следующие команды:
```
sudo apt-get update
sudo apt install make -y
```
Для установки make на RHEL based дистрибутивы необходимо выполнить следующие команды:
```
sudo dnf makecache
sudo dnf install make -y
```
На основе приложенного в репозитории Makefile возможно использование следующих команд:
 - build:            Сборка Go пакетов и Docker image, указать название образа и tag для image: IMAGE= TAG=
 - conf_firewalld:   Настройка firewalld (при его использовании)
 - conf_ufw:         Настройка ufw (при его использовании)
 - dev-down:         Удаление базы данных на основе docker-compose
 - dev-up:           Запуск базы данных на основе docker-compose
 - down:             Удаление базы данных и сервера на основе docker-compose
 - help:             Подсказка по доступным командам
 - install-astra:    Установка Docker на Astra Linux
 - install-debian:   Установка Docker для Debian based дистрибутивов
 - install-redos:    Установка Docker на РедОС
 - install-rhel:     Установка Docker для RHEL based дистрибутивов
 - logs-dev:         Получить логи базы данных
 - logs:             Получить логи инсталляции
 - test:             Проверка работоспособности инсталляции
 - up:               Запуск базы данных и сервера на основе docker-compose

Для получения списка доступных команд необходимо написать "make" или "make help". Команды необходимо выполнять с помощью sudo. При использовании команды "make build" возможно указать название и тэг для создаваемого образа следующим образом: "make build TAG=*tag* IMAGE=*image_name*". По умолчанию, эти значения равны "myserver" и "v1.0" соответственно. При сборке образа и указании новых значений для вышеупомянутых переменных данные образа в "docker-compose.yml" будут автоматически обновлены.

При изменении порта, который будет открыт на сервере для обеспечения доступа к веб-серверу, необходимо в Makefile для команды "make test" указывать порт "make test PORT=*port*, для команды "make conf_firewalld/conf_ufw" необходимо указывать порт, сеть и маску сети, для которых будет открыт доступ "make conf_firewalld/conf_ufw PORT=*port* NET=*net* MASK=*net_mask*". Значение сети, маски и порты, по умолчанию, равны 172.26.76.0, 24 и 58080 соответственно.

### Использование Ansible для развертывания инфраструктуры
Ansible - система управления конфигурациями, использующая императивный метод управления. Для использования данных ролей необходима версия Ansible не ниже 2.11.
Для установки Ansible определенной версии необходимо выполнить следующую команду:
```
python3 -m pip install --user ansible-core==*version*
```
Для установки необходимых модулей необходимо выполнить следующую команду:
```
ansible-galaxy install -r requirements.yml
```
В данном проекте имеются две роли: по настройке firewall и docker, и задания по созданию и удалению контейнеров. Роль для docker включает в себя настройку docker для дистрибутивов Astra Linux и РедОС. Для настройки прочих дистрибутивов возможно использовать преднаписанную роль https://github.com/geerlingguy/ansible-role-docker/tree/master, где значения переменных в "defaults/main.yml" похожи на значения переменных для данной роли.

Перед запуском роли ansible-role-firewall необходимо отредактировать значения в файле "roles/ansible-role-firewall/defaults/main.yml":
 - firewall_state - определяет статус firewall (started, stopped, restarted);
 - firewall_enabled_at_boot - добавлять ли firewall в автозагрузку (boolean);
 - firewall_allowed_tcp_ports - список разрешенных TCP портов;
 - firewall_allowed_udp_ports - список разрешенных UDP портов;
 - firewall_enable_ipv6 - требуется ли использование ipv6 (boolean);
 - firewall_disable_firewalld - отключить ли firewalld (boolean);
 - firewall_disable_ufw - отключить ли ufw (boolean).

Перед запуском роли ansible-role-docker необходимо отредактировать значения в файле "roles/ansible-role-docker/defaults/main.yml":
 - install_docker_compose - требуется ли установки docker-compose (boolean);
 - docker_compose_state - состояние пакета docker-compose (installed, latest, absent, removed);
 - docker_service_state - определяет статус docker (started, stopped, restarted);
 - docker_service_enabled - добавлять ли docker в автозагрузку (boolean);
 - docker_state - состояние пакета docker (installed, latest, absent, removed);
 - docker_daemon_options - параметры для docker демона (следует указывать, если требуется, например, использование прокси для выхода в интернет, определить размер лог файлов для docker или использование собственных репозиториев на HTTP) Пример: строка для репозиториев на HTTP - "insecure-registries" : [ "10.55.10.43:8123" ].

В файле "ansible.cfg" необходимо указать пользователя, под которым будет осуществляться подключение. Важно: для этого пользователя должна быть добавлена публичная часть ssh ключа для подключения без пароля, а также добавлена возможность выполнять команды sudo без ввода пароля.
В файле "inventory.yml" необходимо указать сервер, на который будет подключаться Ansible. Важно: FQDN данного сервера должен разрешаться в IP адрес (необходима запись в "/etc/hosts" или в службу DNS).

Для запуска скриптов необходимо использовать следующую команду:
 ```
 cd ansible
 ansible-playbook playbook.yml --tags "*tag*"
 ```
, где в качестве тэга возможно указать следующие значения:
 - setup - одновременная настройка firewall и docker;
 - firewall - настройка только firewall;
 - docker - настройка только docker;
 - deploy - развертывание всей инфраструктуры;
 - deploy_infra - развертывание только инфраструктуры (в данном случае только СУБД);
 - deploy_db - развертывание только СУБД;
 - build_web - сборка docker образа веб-сервера;
 - deploy_web - развертывание только веб-сервера;
 - destroy_infra - удаление только инфраструктуры (в данном случае только СУБД);
 - destroy_db - удаление только СУБД;
 - destroy_web - удаление только веб-сервера;
 - destroy - удаление всей инфраструктуры.

Пример: настройка firewall и docker и развертывание всех сервисов:
```
ansible-playbook playbook.yml --tags "setup,deploy"
```