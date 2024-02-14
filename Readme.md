# OONI Devops

This repository contains the code necessary for managing the OONI
infrastructure as code and all the necessary tooling for day to day operations
of it.

## Setup

* Install [terraform](https://developer.hashicorp.com/terraform/install)
* Install [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Using

For most up to date information, always look at the github workflow.

You should have setup the following environment variables:
```
AWS_ACCESS_KEY_ID=XXXX
AWS_SECRET_ACCESS_KEY=YYYY
TF_VAR_aws_access_key_id=XXX
TF_VAR_aws_secret_access_key=YYYY
TF_VAR_datadog_api_key=ZZZZ
```

### Deploying IaC

```
cd tf/environments/production/
terraform plan
```

Check the plan looks good, then apply:

```
terraform apply
```

This will update the ansible inventory file.

### Deploying Configuration

You can now run:
```
ansible-playbook -i inventory.ini --check --diff playbook.yml
```

And the apply it with:

```
ansible-playbook -i inventory.ini playbook.yml
```

