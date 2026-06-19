# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/repositories/customer_repository'
require_relative '../../lib/repositories/visit_repository'
require_relative '../../lib/services/visit_service'

RSpec.describe VisitService do
  subject(:service) { described_class.new(customer_repo:, visit_repo:) }

  let(:customer_repo) { instance_double(CustomerRepository) }
  let(:visit_repo)    { instance_double(VisitRepository) }

  before do
    allow(visit_repo).to receive(:create)
    allow(customer_repo).to receive(:upsert)
  end

  describe '#record' do
    context 'when customer does not exist yet' do
      before { allow(customer_repo).to receive(:find).with('c1').and_return(nil) }

      it 'upserts the customer with total_visits = 1' do
        service.record(customer_id: 'c1', device_id: 'd1')
        expect(customer_repo).to have_received(:upsert).with(
          id: 'c1', total_visits: 1, last_connection: instance_of(Time)
        )
      end
    end

    context 'when customer already exists' do
      before do
        allow(customer_repo).to receive(:find).with('c1').and_return(
          { id: 'c1', total_visits: 2, last_connection: Time.now.utc }
        )
      end

      it 'upserts the customer with incremented total_visits' do
        service.record(customer_id: 'c1', device_id: 'd1')
        expect(customer_repo).to have_received(:upsert).with(
          id: 'c1', total_visits: 3, last_connection: instance_of(Time)
        )
      end
    end

    it 'calls visit_repo.create with customer_id, device_id and a Time' do
      allow(customer_repo).to receive(:find).and_return(nil)
      service.record(customer_id: 'c1', device_id: 'd1')
      expect(visit_repo).to have_received(:create).with(
        customer_id: 'c1', device_id: 'd1', visited_at: instance_of(Time)
      )
    end

    it 'returns nil' do
      allow(customer_repo).to receive(:find).and_return(nil)
      expect(service.record(customer_id: 'c1', device_id: 'd1')).to be_nil
    end
  end
end
