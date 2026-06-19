# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/errors'
require_relative '../../lib/repositories/visit_repository'

RSpec.describe VisitRepository do
  subject(:repo) { described_class.new(DB) }

  before do
    DB[:customers].insert(id: 'c1', total_visits: 1, last_connection: Time.now.utc)
  end

  describe '#create' do
    it 'inserts a visit and returns it' do
      result = repo.create(customer_id: 'c1', device_id: 'd1', visited_at: Time.now.utc)

      expect(result[:customer_id]).to eq('c1')
      expect(result[:device_id]).to eq('d1')
    end

    it 'raises PersistenceError if Sequel fails' do
      failing_db = double('db')
      allow(failing_db).to receive(:[]).and_raise(Sequel::Error)
      expect { described_class.new(failing_db).create(customer_id: 'c1', device_id: 'd1', visited_at: Time.now.utc) }
        .to raise_error(PersistenceError)
    end
  end

  describe '#by_hour' do
    it 'returns a hash grouped by hour' do
      repo.create(customer_id: 'c1', device_id: 'd1', visited_at: Time.now.utc)

      result = repo.by_hour(since: Time.now.utc - 3600)

      expect(result).to be_a(Hash)
      expect(result.values.sum).to eq(1)
    end

    it 'excludes visits before the since timestamp' do
      repo.create(customer_id: 'c1', device_id: 'd1', visited_at: Time.now.utc - 7200)
      repo.create(customer_id: 'c1', device_id: 'd1', visited_at: Time.now.utc)

      result = repo.by_hour(since: Time.now.utc - 3600)

      expect(result.values.sum).to eq(1)
    end

    it 'raises PersistenceError if Sequel fails' do
      failing_db = double('db')
      allow(failing_db).to receive(:[]).and_raise(Sequel::Error)
      expect { described_class.new(failing_db).by_hour(since: Time.now.utc) }
        .to raise_error(PersistenceError)
    end
  end
end
