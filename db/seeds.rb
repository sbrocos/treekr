# frozen_string_literal: true

require 'sequel'
require 'time'

Sequel.extension :migration
Sequel.default_timezone = :utc

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'sqlite://treekr.db'))
Sequel::Migrator.run(DB, File.join(__dir__, 'migrate'))

DB[:visits].delete
DB[:customers].delete

puts 'Seeding database...'

now = Time.now.utc

customers = [
  { id: 'alice_01',   visits: 20, devices: %w[door_a door_b] },
  { id: 'bob_02',     visits: 12, devices: %w[door_a] },
  { id: 'carol_03',   visits: 7,  devices: %w[door_b door_c] },
  { id: 'david_04',   visits: 15, devices: %w[door_a door_c] },
  { id: 'eve_05',     visits: 3,  devices: %w[door_b] },
  { id: 'frank_06',   visits: 9,  devices: %w[door_a] },
  { id: 'grace_07',   visits: 1,  devices: %w[door_c] },
  { id: 'henry_08',   visits: 5,  devices: %w[door_a door_b] }
]

# Business hours only (8h-22h) — nighttime slots stay at zero
ACTIVE_HOURS = (8..21).to_a

customers.each do |c|
  visit_times = c[:visits].times.map do |i|
    hours_ago = 23 - ACTIVE_HOURS.sample
    now - (hours_ago * 3600) - (rand(0..59) * 60) - (i * 13)
  end

  last_connection = visit_times.max

  DB[:customers].insert(
    id:              c[:id],
    total_visits:    c[:visits],
    last_connection: last_connection
  )

  visit_times.each do |visited_at|
    DB[:visits].insert(
      customer_id: c[:id],
      device_id:   c[:devices].sample,
      visited_at:  visited_at
    )
  end

  trees = c[:visits] / 5
  puts "  #{c[:id]}: #{c[:visits]} visits, #{trees} trees planted 🌳"
end

total_visits = customers.sum { |c| c[:visits] }
puts "\nDone. #{customers.size} customers, #{total_visits} visits inserted."
