# frozen_string_literal: true

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
  end

  def find(id)
    @db[@table_name].where(id:).first
  end

  def all
    @db[@table_name].all.to_a
  end
end
