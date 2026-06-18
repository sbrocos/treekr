# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:visits) do
      primary_key :id
      String :customer_id, null: false
      String :device_id, null: false
      DateTime :visited_at, null: false

      index :customer_id
      index :device_id
      index :visited_at

      foreign_key [:customer_id], :customers
    end
  end
end
