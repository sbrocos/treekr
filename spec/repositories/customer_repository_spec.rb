# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/errors'
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

    it 'raises PersistenceError if Sequel fails' do
      dataset = double.tap { |d| allow(d).to receive(:insert_conflict).and_raise(Sequel::Error) }
      failing_repo = described_class.new(double('db', :[] => dataset))
      expect { failing_repo.upsert(id: 'c1', total_visits: 1, last_connection: Time.now.utc) }
        .to raise_error(PersistenceError)
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

    it 'raises PersistenceError if Sequel fails' do
      failing_db = double('db')
      allow(failing_db).to receive(:[]).and_raise(Sequel::Error)
      expect { described_class.new(failing_db).find('c1') }.to raise_error(PersistenceError)
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

    it 'raises PersistenceError if Sequel fails' do
      failing_db = double('db')
      allow(failing_db).to receive(:[]).and_raise(Sequel::Error)
      expect { described_class.new(failing_db).all }.to raise_error(PersistenceError)
    end
  end

  describe '#transaction' do
    it 'yields and executes the block' do
      expect { |b| repo.transaction(&b) }.to yield_control
    end
  end
end
