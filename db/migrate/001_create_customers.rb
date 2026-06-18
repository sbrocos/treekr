# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:customers) do
      String :id, primary_key: true, null: false
      Integer :total_visits, null: false, default: 0
      DateTime :last_connection, null: false
    end
  end
end
