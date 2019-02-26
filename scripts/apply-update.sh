#!/bin/bash
echo ./apply-update.sh starts here...

set -ex

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

RBENV_PATH=${HOME}/.rbenv
RBENV_BIN_PATH=${RBENV_PATH}/bin
RBENV_SHIMS_PATH=${RBENV_PATH}/shims

PATH=${RBENV_BIN_PATH}:${RBENV_SHIMS_PATH}:$PATH

project_root=${HOME}/web-shop
instance_name=${1}
package_name=${2}

version_part=$(cat ${HOME}/VERSION)
backup_date_part=$(date +"%Y-%m-%d--%H-%M")
backup_dir_path=${project_root}_backup_${backup_date_part}_v${version_part}

db_path=${project_root}/db/${instance_name}.sqlite3
stash_db_dir=/tmp/db/
stash_db_path=/tmp/db/${instance_name}.sqlite3


systemctl stop puma-${instance_name}.service

su ${SUDO_USER} <<USERCOMMANDS
set -ex

PATH=${RBENV_BIN_PATH}:${RBENV_SHIMS_PATH}:$PATH

mkdir -p ${stash_db_dir}

echo " # Creating backup"
if [ -f ${db_path} ]; then
   echo " # Put db to temporary stash"
   cp ${db_path} ${stash_db_path}
#  mv ${db_path} ${backup_dir_path}
fi

mv ${project_root} ${backup_dir_path}


echo " # Extracting app package"
mkdir -p ${project_root}
tar -xzf ${HOME}/${package_name} -C ${project_root}

if [ -f ${stash_db_path} ]; then
    echo "# Restore DB from stash"
    mv ${stash_db_path} ${db_path}
fi

echo " # Installing app dependencies"
cd ${project_root}
bundle install

echo " # Configuring app"

cat > ${project_root}/config/environments/${instance_name}.rb <<EOL
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.serve_static_files = false
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
end
EOL

cat >> ${project_root}/config/database.yml <<EOL

${instance_name}:
  <<: *default
  database: db/${instance_name}.sqlite3
EOL

RAILS_ENV=${instance_name} bundle exec rake db:migrate

cp ${HOME}/VERSION ${project_root}/VERSION
USERCOMMANDS

cat > /etc/systemd/system/puma-${instance_name}.service <<EOL
[Unit]
Description=puma daemon
After=network.target

[Service]
Environment=RAILS_ENV=${instance_name}
User=${SUDO_USER}
Group=${SUDO_USER}
WorkingDirectory=${project_root}
ExecStart=${RBENV_BIN_PATH}/rbenv exec bundle exec puma -C config/puma.rb
ExecStop=${RBENV_BIN_PATH}/rbenv exec bundle exec pumactl -S tmp/pids/puma.state stop
[Install]
WantedBy=multi-user.target
EOL

echo " # Restart services"
systemctl enable puma-${instance_name}.service
systemctl start puma-${instance_name}.service

echo "# Clenup"
rm ${HOME}/${package_name}
rm ${HOME}/apply-update.sh