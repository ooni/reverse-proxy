resource "aws_security_group" "pg" {
  description = "controls access to postgresql database"

  vpc_id = var.vpc_id
  name   = "${var.name}-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = var.tags
}

resource "aws_db_subnet_group" "pg" {
  name       = "${var.name}-sng"
  subnet_ids = var.subnet_ids

  tags = merge(
    { Name = "Main" },
    var.tags
  )
}

### PostgreSQL database
resource "aws_db_instance" "pg" {
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "16.1"
  instance_class          = var.db_instance_class
  identifier              = var.name
  db_name                 = var.pg_db_name
  username                = var.pg_username
  password                = var.pg_password
  parameter_group_name    = "default.postgres16"
  db_subnet_group_name    = aws_db_subnet_group.pg.name
  vpc_security_group_ids  = [aws_security_group.pg.id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  publicly_accessible     = true

  # Enable deletion protection in production
  deletion_protection = true

  # Comment this out in production
  # apply_immediately = true
}
