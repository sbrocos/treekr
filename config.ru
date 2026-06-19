# frozen_string_literal: true

require 'sequel'
require_relative 'app'

Sequel.extension :migration
Sequel::Migrator.run(DB, File.join(__dir__, 'db', 'migrate'))

run Sinatra::Application
