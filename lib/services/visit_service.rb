# frozen_string_literal: true

class VisitService
  VISITS_PER_TREE = (ENV['VISITS_PER_TREE'] || 5).to_i

  def initialize(customer_repo:, visit_repo:)
    @customer_repo = customer_repo
    @visit_repo = visit_repo
  end

  def record(customer_id:, device_id:)
    customer = @customer_repo.find(customer_id)
    total_visits = (customer ? customer[:total_visits] : 0) + 1
    now = Time.now.utc

    @visit_repo.create(customer_id:, device_id:, visited_at: now)
    @customer_repo.upsert(id: customer_id, total_visits:, last_connection: now)

    nil
  end
end
