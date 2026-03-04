resource "aws_ecs_task_definition" "nginxtf_task" {
  family                   = "nginxtf-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::142764079456:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "nginx-container"
      image     = "142764079456.dkr.ecr.us-west-2.amazonaws.com/nie/nginx:latest"
      cpu       = 0
      essential = true

      entryPoint = [
        "/tmp/CrowdStrike/rootfs/lib/ld-linux-aarch64.so.1",
        "--library-path",
        "/tmp/CrowdStrike/rootfs/lib64",
        "/tmp/CrowdStrike/rootfs/bin/bash",
        "/tmp/CrowdStrike/rootfs/entrypoint-ecs.sh",
        "/docker-entrypoint.sh",
        "nginx",
        "-g",
        "daemon off;"
      ]

      environment = [
        {
          name  = "FALCONCTL_OPTS"
          value = "--cid=E7B6821C49764043AA69EA4885711078-C0"
        }
      ]

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "crowdstrike-falcon-volume"
          containerPath = "/tmp/CrowdStrike"
          readOnly      = true
        }
      ]

      dependsOn = [
        {
          containerName = "crowdstrike-falcon-init-container"
          condition     = "COMPLETE"
        }
      ]

      linuxParameters = {
        capabilities = {
          add = ["SYS_PTRACE"]
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/nginx-task"
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "crowdstrike-falcon-init-container"
      image     = "142764079456.dkr.ecr.us-west-2.amazonaws.com/nie/falcon-container:7.34.0-7306"
      cpu       = 0
      essential = false

      entryPoint = [
        "/bin/bash",
        "-c",
        "chmod u+rwx /tmp/CrowdStrike && mkdir -p /tmp/CrowdStrike/rootfs/lib && cp /lib/ld-linux-aarch64.so.1 /tmp/CrowdStrike/rootfs/lib/  && cp -r /bin /etc /lib64 /usr /entrypoint-ecs.sh /tmp/CrowdStrike/rootfs && chmod -R a=rX /tmp/CrowdStrike"
      ]

      mountPoints = [
        {
          sourceVolume  = "crowdstrike-falcon-volume"
          containerPath = "/tmp/CrowdStrike"
          readOnly      = false
        }
      ]

      readonlyRootFilesystem = true
      user                   = "0:0"
    }
  ])

  volume {
    name = "crowdstrike-falcon-volume"
  }
}
