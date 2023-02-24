[{
    "name": "redis",
    "image": "docker.io/library/redis:latest@sha256:579dd1c5fc096aeac8d20bac605c95e9cbea11327243dec4da93e507af90c5a2",
    "cpu": 0,
    "links": [],
    "portMappings": [],
    "essential": true,
    "entryPoint": [],
    "command": [],
    "environment": [],
    "environmentFiles": [],
    "mountPoints": [],
    "volumesFrom": [],
    "linuxParameters": {
        "devices": [],
        "tmpfs": []
    },
    "secrets": [],
    "dependsOn": [],
    "dnsServers": [],
    "dnsSearchDomains": [],
    "extraHosts": [],
    "dockerSecurityOptions": [],
    "dockerLabels": {},
    "ulimits": [],
    "logConfiguration": ${log_configuration},
    "healthCheck": {
        "command": [
            "CMD",
            "redis-cli",
            "ping"
        ],
        "interval": 5,
        "timeout": 30,
        "retries": 10
    },
    "systemControls": []
}]