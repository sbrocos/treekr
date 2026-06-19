# frozen_string_literal: true

class CustomerService
  VISITS_PER_TREE = begin
    value = (ENV['VISITS_PER_TREE'] || 5).to_i
    raise ArgumentError, 'VISITS_PER_TREE must be a positive integer' unless value.positive?

    value
  end

  def initialize(customer_repo:)
    @customer_repo = customer_repo
  end

  def all
    @customer_repo.all.map { |c| enrich(c) }
  end

  def find(id)
    customer = @customer_repo.find(id)
    return nil unless customer

    enrich(customer)
  end

  private

  def enrich(customer)
    customer.merge(trees_planted: customer[:total_visits] / VISITS_PER_TREE)
  end
end
