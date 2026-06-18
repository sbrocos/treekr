# frozen_string_literal: true

class VisitRepository
  HOUR_FORMAT = "strftime('%Y-%m-%dT%H:00:00Z', visited_at)"

  def initialize(db)
    @db = db
    @table_name = :visits
  end

  def create(customer_id:, device_id:, visited_at:)
    id = @db[@table_name].insert(customer_id:, device_id:, visited_at:)
    @db[@table_name].where(id:).first
  end

  def by_hour(since:)
    hour_expr = Sequel.lit(HOUR_FORMAT)

    @db[@table_name]
      .where { visited_at >= since }
      .select(hour_expr.as(:hour), Sequel.function(:count, :id).as(:count))
      .group(hour_expr)
      .to_hash(:hour, :count)
  end
end
