Использование Terraform провайдера для Ovirt:
### В случае использования Debian дистрибутивов
sudo apt-get --assume-yes install gcc libxml2-dev python3-dev
### В случае использования RHE дистрибутивов
sudo dnf install -y gcc libxml2-devel python3-devel 
pip3 install -r requirements.txt
export TF_VAR_username=<username>
export TF_VAR_password=<password>
eval '$(python3 get_vnic_id.py <vnic_ovirt_name>)'
terraform apply -auto-approve
