#!/bin/bash
echo ./build.sh starts here...

set -e

echo "build started under user $(whoami)"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

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