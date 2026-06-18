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
    allow(customer_repo).to receive(:upsert).and_return(
      { id: 'c1', total_visits: 1, last_connection: Time.now.utc }
    )
  end

  describe '#record' do
    context 'when customer does not exist yet' do
      before { allow(customer_repo).to receive(:find).with('c1').and_return(nil) }

      it 'returns customer_id in the result' do
        result = service.record(customer_id: 'c1', device_id: 'd1')
        expect(result[:customer_id]).to eq('c1')
      end

      it 'returns total_visits = 1' do
        result = service.record(customer_id: 'c1', device_id: 'd1')
        expect(result[:total_visits]).to eq(1)
      end

      it 'returns trees_planted = 0' do
        result = service.record(customer_id: 'c1', device_id: 'd1')
        expect(result[:trees_planted]).to eq(0)
      end

      it 'returns last_connection close to now' do
        result = service.record(customer_id: 'c1', device_id: 'd1')
        expect(Time.parse(result[:last_connection])).to be_within(2).of(Time.now.utc)
      end
    end

    context 'when customer already exists' do
      before do
        allow(customer_repo).to receive(:find).with('c1').and_return(
          { id: 'c1', total_visits: 2, last_connection: Time.now.utc }
        )
      end

      it 'increments total_visits' do
        result = service.record(customer_id: 'c1', device_id: 'd1')
        expect(result[:total_visits]).to eq(3)
      end
    end

    context 'when total_visits reaches a multiple of VISITS_PER_TREE' do
      before do
        allow(customer_repo).to receive(:find).with('c1').and_return(
          { id: 'c1', total_visits: VisitService::VISITS_PER_TREE - 1, last_connection: Time.now.utc }
        )
      end

      it 'increments trees_planted' do
        result = service.record(customer_id: 'c1', device_id: 'd1')
        expect(result[:trees_planted]).to eq(1)
      end
    end

    it 'calls visit_repo.create on each invocation' do
      allow(customer_repo).to receive(:find).and_return(nil)
      service.record(customer_id: 'c1', device_id: 'd1')
      expect(visit_repo).to have_received(:create).with(
        customer_id: 'c1', device_id: 'd1', visited_at: instance_of(Time)
      )
    end

    it 'respects a custom VISITS_PER_TREE value' do
      stub_const('VisitService::VISITS_PER_TREE', 3)
      allow(customer_repo).to receive(:find).and_return({ id: 'c1', total_visits: 2, last_connection: Time.now.utc })
      expect(service.record(customer_id: 'c1', device_id: 'd1')[:trees_planted]).to eq(1)
    end
  end
end
