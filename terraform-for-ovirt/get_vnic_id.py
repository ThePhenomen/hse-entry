import ovirtsdk4 as sdk
import sys
import os
import tfvars

tfv = tfvars.LoadSecrets()

connection = sdk.Connection(
    url=tfv["url"],
    username=os.environ["TF_VAR_username"],
    password=os.environ["TF_VAR_password"],
    insecure=True,
)

profiles_service = connection.system_service().vnic_profiles_service()
profile_id = None
for profile in profiles_service.list():
    if profile.name == sys.argv[1]:
        profile_id = profile.id
        break

print('export TF_VAR_vnic_id={}'.format(profile_id))