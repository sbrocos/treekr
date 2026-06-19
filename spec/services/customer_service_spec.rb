# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/repositories/customer_repository'
require_relative '../../lib/services/visit_service'
require_relative '../../lib/services/customer_service'

RSpec.describe CustomerService do
  subject(:service) { described_class.new(customer_repo:) }

  let(:customer_repo) { instance_double(CustomerRepository) }

  describe '#all' do
    context 'when there are no customers' do
      before { allow(customer_repo).to receive(:all).and_return([]) }

      it 'returns an empty array' do
        expect(service.all).to eq([])
      end
    end

    context 'when customers exist' do
      let(:customers) do
        [
          { id: 'c1', total_visits: 3, last_connection: Time.now.utc },
          { id: 'c2', total_visits: 10, last_connection: Time.now.utc }
        ]
      end

      before { allow(customer_repo).to receive(:all).and_return(customers) }

      it 'includes trees_planted in each customer' do
        result = service.all
        expect(result.map { |c| c[:trees_planted] }).to all(be_an(Integer))
      end

      it 'does not mutate the original hashes' do
        service.all
        expect(customers.first).not_to have_key(:trees_planted)
      end
    end
  end

  describe '#find' do
    context 'when the customer exists' do
      let(:customer) { { id: 'c1', total_visits: 5, last_connection: Time.now.utc } }

      before { allow(customer_repo).to receive(:find).with('c1').and_return(customer) }

      it 'returns the customer enriched with trees_planted' do
        result = service.find('c1')
        expect(result[:trees_planted]).to be_an(Integer)
      end

      it 'preserves existing customer fields' do
        result = service.find('c1')
        expect(result[:id]).to eq('c1')
        expect(result[:total_visits]).to eq(5)
      end
    end

    context 'when the customer does not exist' do
      before { allow(customer_repo).to receive(:find).with('unknown').and_return(nil) }

      it 'returns nil' do
        expect(service.find('unknown')).to be_nil
      end
    end
  end

  describe 'trees_planted calculation' do
    before { allow(customer_repo).to receive(:find).with('c1').and_return(customer) }

    context 'when total_visits is below threshold' do
      let(:customer) { { id: 'c1', total_visits: CustomerService::VISITS_PER_TREE - 1, last_connection: Time.now.utc } }

      it 'returns trees_planted = 0' do
        expect(service.find('c1')[:trees_planted]).to eq(0)
      end
    end

    context 'when total_visits reaches a multiple of VISITS_PER_TREE' do
      let(:customer) { { id: 'c1', total_visits: CustomerService::VISITS_PER_TREE, last_connection: Time.now.utc } }

      it 'returns trees_planted = 1' do
        expect(service.find('c1')[:trees_planted]).to eq(1)
      end
    end

    context 'with a custom VISITS_PER_TREE' do
      let(:customer) { { id: 'c1', total_visits: 3, last_connection: Time.now.utc } }

      it 'uses the configured threshold' do
        stub_const('CustomerService::VISITS_PER_TREE', 3)
        expect(service.find('c1')[:trees_planted]).to eq(1)
      end
    end
  end
end
