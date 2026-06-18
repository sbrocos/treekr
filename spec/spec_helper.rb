# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'sequel'

Sequel.extension :migration
Sequel.default_timezone = :utc

DB = Sequel.sqlite
Sequel::Migrator.run(DB, File.join(__dir__, '..', 'db', 'migrate'))

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.order = :random

  config.before do
    DB[:visits].delete
    DB[:customers].delete
  end
end
