Использование Terraform провайдера для Ovirt:
1. sudo apt-get --assume-yes install gcc libxml2-dev python3-dev (для Debian дистрибутивов)
1. sudo dnf install -y gcc libxml2-devel python3-devel (для RHEL дистрибутивов)
2. pip3 install -r requirements.txt
3. export TF_VAR_username=<username>
4. export TF_VAR_password=<password>
5. eval '$(python3 get_vnic_id.py <vnic_ovirt_name>)'
6. terraform apply -auto-approve
