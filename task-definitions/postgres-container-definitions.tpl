[
    {
        "name": "postgres",
        "image": "docker.io/library/postgres:13@sha256:ecf9c1734b958041a3ce8c347e45f3e782c46be2ea30af68187877be1c063092",
        "cpu": 0,
        "links": [],
        "portMappings": [],
        "essential": true,
        "entryPoint": [],
        "command": [],
        "environment": [
            {
                "name": "POSTGRES_USER",
                "value": "airflow"
            },
            {
                "name": "POSTGRES_PASSWORD",
                "value": "airflow"
            },
            {
                "name": "POSTGRES_DB",
                "value": "airflow"
            }
        ],
        "environmentFiles": [],
        "mountPoints": [
            {
                "sourceVolume": "postgres-db-volume",
                "containerPath": "/var/lib/postgresql/data"
            }
        ],
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
                "pg_isready",
                "-U",
                "airflow"
            ],
            "interval": 5,
            "timeout": 5,
            "retries": 5
        },
        "systemControls": []
    }
]