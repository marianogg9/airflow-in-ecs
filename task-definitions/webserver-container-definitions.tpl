[
    {
        "name": "airflow-webserver",
        "image": "docker.io/apache/airflow:2.5.1@sha256:eef7c1cfcdd60a8dff245f2388aca35c4eaaa3077342357be3b1a6e46d62aa84",
        "cpu": 0,
        "links": [],
        "portMappings": [
            {
                "containerPort": 8080,
                "hostPort": 8080,
                "protocol": "tcp"
            }
        ],
        "essential": true,
        "entryPoint": [],
        "command": [
            "webserver"
        ],
        "environment": [
            {
                "name": "AIRFLOW__CORE__SQL_ALCHEMY_CONN",
                "value": "postgresql+psycopg2://airflow:airflow@postgres.airflow.local/airflow"
            },
            {
                "name": "AIRFLOW__CORE__LOAD_EXAMPLES",
                "value": "False"
            },
            {
                "name": "AIRFLOW__CELERY__BROKER_URL",
                "value": "redis://:@redis.airflow.local:6379/0"
            },
            {
                "name": "AIRFLOW__CELERY__RESULT_BACKEND",
                "value": "db+postgresql://airflow:airflow@postgres.airflow.local/airflow"
            },
            {
                "name": "AIRFLOW__CORE__EXECUTOR",
                "value": "CeleryExecutor"
            },
            {
                "name": "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION",
                "value": "true"
            },
            {
                "name": "AIRFLOW__API__AUTH_BACKENDS",
                "value": "airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session"
            },
            {
                "name": "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN",
                "value": "postgresql+psycopg2://airflow:airflow@postgres.airflow.local/airflow"
            }
        ],
        "environmentFiles": [],
        "mountPoints": [
            {
                "sourceVolume": "airflow",
                "containerPath": "/opt/airflow/dags"
            }
        ],
        "volumesFrom": [],
        "linuxParameters": {
            "devices": [],
            "tmpfs": []
        },
        "secrets": [],
        "dependsOn": [],
        "user": "50000:0",
        "dnsServers": [],
        "dnsSearchDomains": [],
        "extraHosts": [],
        "dockerSecurityOptions": [],
        "dockerLabels": {},
        "ulimits": [],
        "logConfiguration": ${log_configuration},
        "systemControls": []
    }
]
