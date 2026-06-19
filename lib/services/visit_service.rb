# frozen_string_literal: true

class VisitService
  VISITS_PER_TREE = begin
    value = (ENV['VISITS_PER_TREE'] || 5).to_i
    raise ArgumentError, 'VISITS_PER_TREE must be a positive integer' unless value.positive?

    value
  end

  def initialize(customer_repo:, visit_repo:)
    @customer_repo = customer_repo
    @visit_repo = visit_repo
  end

  def record(customer_id:, device_id:)
    validate_customer_id(customer_id)
    validate_device_id(device_id)

    customer = @customer_repo.find(customer_id)
    total_visits = (customer ? customer[:total_visits] : 0) + 1
    now = Time.now.utc

    @customer_repo.transaction do
      @customer_repo.upsert(id: customer_id, total_visits:, last_connection: now)
      @visit_repo.create(customer_id:, device_id:, visited_at: now)
    end

    true
  end

  def hourly_stats
    since = Time.now.utc - (24 * 3600)
    @visit_repo.by_hour(since:)
  end

  private

  def validate_customer_id(customer_id)
    raise ArgumentError, 'customer_id is required' if customer_id.to_s.strip.empty?
  end

  def validate_device_id(device_id)
    raise ArgumentError, 'device_id is required' if device_id.to_s.strip.empty?
  end
end
