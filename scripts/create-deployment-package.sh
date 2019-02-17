#!/bin/bash
echo ./create-deployment-package.sh starts here...

set -ex

version=${1}

cd web-shop

RAILS_ENV=production rake assets:precompile

echo ${version} > VERSION

mkdir -p ${HOME}/artifacts

tar -czf ${HOME}/artifacts/web-shop-${build_number}.tar.gz \
--exclude=README.md \
--exclude=features \
--exclude=test \
.

cd -

ls ${HOME}/artifacts/