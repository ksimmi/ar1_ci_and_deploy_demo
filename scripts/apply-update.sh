#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

RBENV_PATH=${HOME}/.rbenv
RBENV_BIN_PATH=${RBENV_PATH}/bin
RBENV_SHIMS_PATH=${RBENV_PATH}/shims
MYSQL_DB_NAME="todo_db"
MYSQL_USER_NAME="todouser"

PATH=${RBENV_BIN_PATH}:${RBENV_SHIMS_PATH}:$PATH

project_root=${HOME}/web-shop
instance_name=${1}
package_name=${2}

version_part=$(cat ${project_root}/VERSION)
backup_date_part=$(date +"%Y-%m-%d--%H-%M")
backup_dir_path=${project_root}_backup_${backup_date_part}_v${version_part}

systemctl stop puma-${instance_name}.service

su ${SUDO_USER} <<USERCOMMANDS
PATH=${RBENV_BIN_PATH}:${RBENV_SHIMS_PATH}:$PATH
echo " # Creating backup"
mv ${project_root} ${backup_dir_path}
mysqldump -u${MYSQL_USER_NAME} ${MYSQL_DB_NAME} > ${backup_dir_path}

echo " # Extracting app package"
mkdir ${project_root}
tar -xzf ${HOME}/${package_name} -C ${project_root}

echo " # Installing app dependencies"
cd ${project_root}
bundle install

echo " # Configuring app"
rake db:migrate
USERCOMMANDS

echo " # Restart services"
systemctl start puma-${instance_name}.services
systemctl restart nginx.services

echo "# Clenup"
rm ${HOME}/${package_name}
rm ${HOME}/apply-update.sh