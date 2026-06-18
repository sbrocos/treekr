# frozen_string_literal: true

require 'sequel'

database_url = ENV.fetch('DATABASE_URL', 'sqlite://treekr.db')
db = Sequel.connect(database_url)

Sequel.extension :migration
Sequel::Migrator.run(db, File.join(__dir__, 'migrate'))

puts 'Migrations applied successfully.'
