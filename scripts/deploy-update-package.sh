#!/bin/bash

echo ./deploy-update-package.sh starts here...

set -ex

host=${1}
id_rsa_key_path=${2}
instance_name=${3}
version=${4}
package_name=web-shop-${version}.tar.gz
package_name_path=${HOME}/artifacts/${package_name}

script_execution_dir=$(pwd)
echo Scripts runed under $script_execution_dir directory

chmod 700 keys
chmod 600 ${id_rsa_key_path}

scp scripts/apply-update.sh ${host}:~
scp ${package_name_path} ${host}:~

echo ${version} > VERSION
scp VERSION ${host}:~

ssh ${host} <<EOL
chmod +x apply-update.sh
sudo ./apply-update.sh ${instance_name} ${package_name}
EOL