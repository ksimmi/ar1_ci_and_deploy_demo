#!/bin/bash
echo ./build.sh starts here...

set -ex

echo "build started under user $(whoami)"

cd ./scripts
source helpers/load_rbenv.sh
cd -

rbenv install 2.5.1 || true
rbenv local 2.5.1

gem install bundler -v 1.16.1
gem install rake

cd web-shop

rails_pid=$(lsof -i:3000 | grep ruby | awk '{ print $2 }')
kill -9 $rails_pid

export RAILS_ENV=test
bundle
rake db:migrate
rake db:reset
rake db:seed
rails s -d
#bundle exec cucumber --color
cd -