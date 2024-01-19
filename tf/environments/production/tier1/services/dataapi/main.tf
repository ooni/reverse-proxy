resource "aws_ecs_task_definition" "dataapi" {
  family = "ooni_dataapi"

  container_definitions = <<EOF
[
  {
    "name": "ooni_dataapi"
    "image": "ooni/dataapi:latest",
    "cpu": 0,
    "memory": 128,
  }
]
EOF
}

resource "aws_ecs_service" "dataapi" {
  name            = "ooni_dataapi"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.ooni_dataapi.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
