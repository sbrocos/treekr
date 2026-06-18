# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 4.0'

gem 'puma',    '~> 6.0'
gem 'sequel',  '~> 5.0'
gem 'sinatra', '~> 4.0'
gem 'sqlite3', '~> 2.0'

group :development do
  gem 'irb'
end

group :development, :test do
  gem 'brakeman',        require: false
  gem 'rubocop',         require: false
  gem 'rubocop-rspec',   require: false
  gem 'rubocop-sequel',  require: false
end

group :test do
  gem 'rack-test', '~> 2.0'
  gem 'rspec',     '~> 3.0'
end
