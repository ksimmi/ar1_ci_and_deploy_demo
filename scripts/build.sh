#!/bin/bash
echo ./build.sh starts here...

set -ex

source helpers/load_rbenv.sh

rbenv install 2.5.1 || true
rbenv local 2.5.1

gem install bundler -v 1.16.1
gem install rake

cd web-shop

export RAILS_ENV=test
bundle
rake db:migrate
rake db:reset
rake db:seed
rails s -d
bundle exec cucumber --color

cd -