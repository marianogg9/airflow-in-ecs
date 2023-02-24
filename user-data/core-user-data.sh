#!/bin/bash
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=airflow-tf
ECS_ENGINE_AUTH_TYPE=docker
ECS_LOGLEVEL=debug
ECS_INSTANCE_ATTRIBUTES={"tier": "core"}
EOF

cat <<EOF >/etc/docker/daemon.json
{"debug": true}
EOF

## s3fs-fuse
mkdir -p /opt/airflow/dags
sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/epel.repo
yum install -y gcc libstdc++-devel gcc-c++ fuse fuse-devel curl-devel libxml2-devel mailcap automake openssl-devel git 
git clone https://github.com/s3fs-fuse/s3fs-fuse
cd s3fs-fuse/
git checkout 895d500
./autogen.sh
./configure --prefix=/usr --with-openssl
make
make install

s3fs ${s3_bucket} -o iam_role=${instance_role} -o allow_other -o host=http://s3.${region}.amazonaws.com /opt/airflow/dags

systemctl restart docker --no-block