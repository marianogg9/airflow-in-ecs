[
    {
        "name": "airflow-scheduler",
        "image": "docker.io/apache/airflow:2.5.1@sha256:eef7c1cfcdd60a8dff245f2388aca35c4eaaa3077342357be3b1a6e46d62aa84",
        "cpu": 0,
        "links": [],
        "portMappings": [],
        "essential": true,
        "entryPoint": [
            "/bin/bash"
        ],
        "command": [
            "-c",
            "function ver() {\n  printf \"%04d%04d%04d%04d\" $${1//./ }\n}\none_meg=1048576\nmem_available=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / one_meg))\ncpus_available=$(grep -cE 'cpu[0-9]+' /proc/stat)\ndisk_available=$(df / | tail -1 | awk '{print $4}')\nwarning_resources=\"false\"\nif (( mem_available < 4000 )) ; then\n  echo\n  echo -e \"\\033[1;33mWARNING!!!: Not enough memory available for Docker.\\e[0m\"\n  echo \"At least 4GB of memory required. You have $(numfmt --to iec $((mem_available * one_meg)))\"\n  echo\n  warning_resources=\"true\"\nfi\nif (( cpus_available < 2 )); then\n  echo\n  echo -e \"\\033[1;33mWARNING!!!: Not enough CPUS available for Docker.\\e[0m\"\n  echo \"At least 2 CPUs recommended. You have $${cpus_available}\"\n  echo\n  warning_resources=\"true\"\nfi\nif (( disk_available < one_meg * 10 )); then\n  echo\n  echo -e \"\\033[1;33mWARNING!!!: Not enough Disk space available for Docker.\\e[0m\"\n  echo \"At least 10 GBs recommended. You have $(numfmt --to iec $((disk_available * 1024 )))\"\n  echo\n  warning_resources=\"true\"\nfi\nif [[ $${warning_resources} == \"true\" ]]; then\n  echo\n  echo -e \"\\033[1;33mWARNING!!!: You have not enough resources to run Airflow (see above)!\\e[0m\"\n  echo \"Please follow the instructions to increase amount of resources available:\"\n  echo \"   https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html#before-you-begin\"\n  echo\nfi\nmkdir -p /opt/airflow/dags\nchown -R \"501:0\" /opt/airflow/dags\nexec /entrypoint airflow scheduler"
        ],
        "environment": [
            {
                "name": "AIRFLOW__CORE__SQL_ALCHEMY_CONN",
                "value": "postgresql+psycopg2://airflow:airflow@postgre.airflow.local/airflow"
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
            },
            {
                "name": "AIRFLOW_UID",
                "value": "0"
            },
            {
                "name": "_AIRFLOW_WWW_USER_CREATE",
                "value": "true"
            },
            {
                "name": "_AIRFLOW_WWW_USER_USERNAME",
                "value": "airflow"
            },
            {
                "name": "_AIRFLOW_DB_UPGRADE",
                "value": "true"
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
        "secrets": ${secrets},
        "dependsOn": [],
        "user": "501:0",
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