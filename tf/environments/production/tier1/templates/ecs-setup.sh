#!/bin/bash

cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${ecs_cluster_name}
ECS_LOGLEVEL=debug
ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(ecs_cluster_tags)}
ECS_ENABLE_TASK_IAM_ROLE=true
EOF

# Install datadog agent
DD_API_KEY=${datadog_api_key} DD_SITE="datadoghq.eu" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"