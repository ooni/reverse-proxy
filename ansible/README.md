### Quickstart

It's recommended to make use of a virtualenv, for example managed using `pyenv virtualenv`:
```
pyenv virtualenv ooni-devops
pyenv activate ooni-devops
```

Install deps:
```
pip install ansible dnspython boto3 passlib
```

Install ansible galaxy modules:
```
ansible-galaxy install -r requirements.yml
```

Setup AWS credentials, you should add 2 profiles called `oonidevops_user_dev` and `oonidevops_user_prod` which have access to the development and production environment respectively

```
[oonidevops_user_dev]
aws_access_key_id = XXX
aws_secret_access_key = YYY
source_profile = default
region = eu-central-1
# ARN of the dev role
role_arn = arn:aws:iam::905418398257:role/oonidevops

[oonidevops_user_prod]
aws_access_key_id = XXX
aws_secret_access_key = YYY
source_profile = default
region = eu-central-1
# ARN of the prod role
role_arn = arn:aws:iam::471112720364:role/oonidevops
```

Run playbook:
```
ansible-playbook playbook.yml -i inventory
```

On macOS you might run into this issue: https://github.com/ansible/ansible/issues/76322

The current workaround is to export the following environment variable before running ansible:
```
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```
