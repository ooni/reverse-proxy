#!/bin/bash

cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${ecs_cluster_name}
ECS_LOGLEVEL=debug
ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(ecs_cluster_tags)}
ECS_ENABLE_TASK_IAM_ROLE=true
EOF

