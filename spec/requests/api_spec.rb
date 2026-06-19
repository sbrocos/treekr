# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app'

RSpec.describe 'API' do
  def app
    Sinatra::Application
  end

  describe 'POST /api/visits' do
    let(:valid_payload) { JSON.generate(customer_id: 'c1', device_id: 'd1') }

    it 'returns 201 with customer data on valid request' do
      post '/api/visits', valid_payload, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      body = JSON.parse(last_response.body, symbolize_names: true)
      expect(body[:id]).to eq('c1')
      expect(body[:total_visits]).to eq(1)
      expect(body[:trees_planted]).to be_an(Integer)
      expect(body[:last_connection]).not_to be_nil
    end

    it 'returns 400 if customer_id is missing' do
      post '/api/visits', JSON.generate(device_id: 'd1'), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to include('customer_id')
    end

    it 'returns 400 if device_id is missing' do
      post '/api/visits', JSON.generate(customer_id: 'c1'), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to include('device_id')
    end

    it 'returns 400 if body is not valid JSON' do
      post '/api/visits', 'not json', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to match(/Invalid JSON/i)
    end
  end

  describe 'GET /api/customers' do
    it 'returns 200 with empty array when no customers' do
      get '/api/customers'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq([])
    end

    it 'returns customers with trees_planted after visits' do
      post '/api/visits', JSON.generate(customer_id: 'c1', device_id: 'd1'), 'CONTENT_TYPE' => 'application/json'
      get '/api/customers'
      body = JSON.parse(last_response.body, symbolize_names: true)
      expect(body.size).to eq(1)
      expect(body.first[:trees_planted]).to be_an(Integer)
    end
  end

  describe 'GET /api/customers/:id' do
    it 'returns 200 with customer data for existing customer' do
      post '/api/visits', JSON.generate(customer_id: 'c1', device_id: 'd1'), 'CONTENT_TYPE' => 'application/json'
      get '/api/customers/c1'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body, symbolize_names: true)
      expect(body[:id]).to eq('c1')
      expect(body[:trees_planted]).to be_an(Integer)
    end

    it 'returns 404 for unknown customer' do
      get '/api/customers/unknown'
      expect(last_response.status).to eq(404)
      expect(JSON.parse(last_response.body)['error']).to eq('Customer not found')
    end
  end

  describe 'GET /api/stats/hourly' do
    it 'returns 200 with exactly 24 buckets' do
      get '/api/stats/hourly'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body.size).to eq(24)
    end

    it 'fills empty hours with visits: 0' do
      get '/api/stats/hourly'
      body = JSON.parse(last_response.body)
      expect(body.map { |b| b['visits'] }).to all(be_a(Integer))
    end

    it 'counts registered visits in the correct bucket' do
      post '/api/visits', JSON.generate(customer_id: 'c1', device_id: 'd1'), 'CONTENT_TYPE' => 'application/json'
      get '/api/stats/hourly'
      body = JSON.parse(last_response.body)
      expect(body.sum { |b| b['visits'] }).to eq(1)
    end
  end

  describe 'GET /' do
    it 'returns 200 with HTML content type' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('text/html')
    end
  end
end
