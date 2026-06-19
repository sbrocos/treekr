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
    allow(customer_repo).to receive(:transaction).and_yield
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

    it 'calls upsert before create' do
      allow(customer_repo).to receive(:find).and_return(nil)
      order = []
      allow(customer_repo).to receive(:upsert) { order << :upsert }
      allow(visit_repo).to receive(:create)    { order << :create }
      service.record(customer_id: 'c1', device_id: 'd1')
      expect(order).to eq(%i[upsert create])
    end

    it 'calls visit_repo.create with customer_id, device_id and a Time' do
      allow(customer_repo).to receive(:find).and_return(nil)
      service.record(customer_id: 'c1', device_id: 'd1')
      expect(visit_repo).to have_received(:create).with(
        customer_id: 'c1', device_id: 'd1', visited_at: instance_of(Time)
      )
    end

    it 'returns true on success' do
      allow(customer_repo).to receive(:find).and_return(nil)
      expect(service.record(customer_id: 'c1', device_id: 'd1')).to be(true)
    end

    context 'when customer_id is invalid' do
      it 'raises ArgumentError if customer_id is nil' do
        expect { service.record(customer_id: nil, device_id: 'd1') }.to raise_error(ArgumentError, /customer_id/)
      end

      it 'raises ArgumentError if customer_id is blank' do
        expect { service.record(customer_id: '  ', device_id: 'd1') }.to raise_error(ArgumentError, /customer_id/)
      end
    end

    context 'when device_id is invalid' do
      it 'raises ArgumentError if device_id is nil' do
        expect { service.record(customer_id: 'c1', device_id: nil) }.to raise_error(ArgumentError, /device_id/)
      end

      it 'raises ArgumentError if device_id is blank' do
        expect { service.record(customer_id: 'c1', device_id: '') }.to raise_error(ArgumentError, /device_id/)
      end
    end
  end
end
