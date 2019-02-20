#!/bin/bash

set -ex

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

RBENV_PATH=${HOME}/.rbenv
RBENV_BIN_PATH=${RBENV_PATH}/bin
RBENV_SHIMS_PATH=${RBENV_PATH}/shims
RUBY_VERSION=2.5.1

package_name=${1}
hostname=${2}
instance_name=${3}

project_root=${HOME}/web-shop

echo "# Installing system dependencies"
apt-get update

cat >> /etc/sudoers <<EOL
${SUDO_USER} ALL=(ALL:ALL) NOPASSWD:${HOME}/apply-update.sh
EOL

apt-get install -y nginx build-essential unzip libssl-dev libreadline-dev libsqlite3-dev

su ${SUDO_USER} <<USERCOMMANDS
echo "# Installing rbenv & ruby-build"

git clone https://github.com/rbenv/rbenv.git ${RBENV_PATH}
cd ${RBENV_PATH} && src/configure && make -C src
mkdir -p ${RBENV_PATH}/plugins

git clone https://github.com/rbenv/ruby-build.git ${RBENV_PATH}/plugins/ruby-build

cd ${HOME}

PATH=${RBENV_BIN_PATH}:${RBENV_SHIMS_PATH}:$PATH
eval "$(rbenv init -)"
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

echo "# Installing ruby"
rbenv install ${RUBY_VERSION}
rbenv local ${RUBY_VERSION}

echo "# Installing bundler"
gem install bundler -v 1.16.1

#gem install libv8 -v '6.7.288.46.1' -- --with-system-v8

echo "# Configuring app"
mkdir -p ${project_root}
tar -xzf ${package_name} -C ${project_root}
cd ${project_root}
rbenv local ${RUBY_VERSION}
bundle install

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

echo "# Starting puma service"
systemctl enable puma-${instance_name}.service
systemctl start puma-${instance_name}.service

echo "# Configuring nginx"
cat > /etc/nginx/sites-available/${hostname} <<EOL
upstream puma {
  server unix:${project_root}/tmp/sockets/puma.sock fail_timeout=0;
}

server {
    listen 80;
    server_name ${hostname};

    root ${project_root}/public;

    location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
    }

    location /version {
        alias ${project_root}/VERSION;
        add_header Content-Type text/plain;
    }

    try_files \$uri/index.html \$uri @puma;
    location / {
        proxy_pass http://puma;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
    }
}
EOL

ln -s /etc/nginx/sites-available/${hostname} /etc/nginx/sites-enabled
systemctl restart nginx.service
