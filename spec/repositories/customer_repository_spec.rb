# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/repositories/customer_repository'

RSpec.describe CustomerRepository do
  subject(:repo) { described_class.new(DB) }

  describe '#upsert' do
    let(:now) { Time.now.utc }
    let(:one_hour_before) { now - 3600 }

    it 'creates a new customer' do
      result = repo.upsert(id: 'c1', total_visits: 1, last_connection: one_hour_before)

      expect(result[:id]).to eq('c1')
      expect(result[:total_visits]).to eq(1)
    end

    it 'updates an existing customer' do
      repo.upsert(id: 'c1', total_visits: 1, last_connection: now)
      repo.upsert(id: 'c1', total_visits: 2, last_connection: now)

      expect(repo.find('c1')[:total_visits]).to eq(2)
      expect(repo.find('c1')[:last_connection]).to be_within(1).of(now)
    end
  end

  describe '#find' do
    it 'returns nil for an unknown id' do
      expect(repo.find('unknown')).to be_nil
    end

    it 'returns the customer for a known id' do
      repo.upsert(id: 'c1', total_visits: 1, last_connection: Time.now.utc)

      expect(repo.find('c1')[:id]).to eq('c1')
    end
  end

  describe '#all' do
    it 'returns an empty array when there are no customers' do
      expect(repo.all).to eq([])
    end

    it 'returns all customers' do
      repo.upsert(id: 'c1', total_visits: 1, last_connection: Time.now.utc)
      repo.upsert(id: 'c2', total_visits: 2, last_connection: Time.now.utc)

      expect(repo.all.size).to eq(2)
    end
  end
end
