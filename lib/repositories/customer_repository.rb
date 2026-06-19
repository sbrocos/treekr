# frozen_string_literal: true

require_relative '../errors'

class CustomerRepository
  def initialize(db)
    @db = db
    @table_name = :customers
  end

  def upsert(id:, total_visits:, last_connection:)
    @db[@table_name]
      .insert_conflict(target: :id, update: { total_visits:, last_connection: })
      .insert(id:, total_visits:, last_connection:)
    find(id)
  rescue Sequel::Error => e
    raise PersistenceError, e.message
  end

  def find(id)
    @db[@table_name].where(id:).first
  rescue Sequel::Error => e
    raise PersistenceError, e.message
  end

  def all
    @db[@table_name].all.to_a
  rescue Sequel::Error => e
    raise PersistenceError, e.message
  end

  def transaction(&)
    @db.transaction(&)
  rescue Sequel::Error => e
    raise PersistenceError, e.message
  end
end
