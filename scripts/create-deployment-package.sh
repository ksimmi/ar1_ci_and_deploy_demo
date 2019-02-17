#!/bin/bash
echo ./create-deployment-package.sh starts here...

set -ex

cd ./scripts
source helpers/load_rbenv.sh
cd -

version=${1}
echo ${version} > VERSION

master_key_value=${2}

cd web-shop

echo $master_key_value > './config/master.key'

RAILS_ENV=production rake assets:precompile

mkdir -p ${HOME}/artifacts

tar -czf ${HOME}/artifacts/web-shop-${version}.tar.gz \
--exclude=README.md \
--exclude=features \
--exclude=test \
.

cd -

ls ${HOME}/artifacts/