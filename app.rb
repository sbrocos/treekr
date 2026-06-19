# frozen_string_literal: true

require 'sinatra'
require 'sequel'
require 'json'

require_relative 'lib/errors'
require_relative 'lib/repositories/customer_repository'
require_relative 'lib/repositories/visit_repository'
require_relative 'lib/services/visit_service'
require_relative 'lib/services/customer_service'

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'sqlite://treekr.db')) unless defined?(DB)
Sequel.default_timezone = :utc

helpers do
  def json(data)
    content_type :json
    JSON.generate(data)
  end

  def visit_service
    @visit_service ||= VisitService.new(
      customer_repo: CustomerRepository.new(DB),
      visit_repo: VisitRepository.new(DB)
    )
  end

  def customer_service
    @customer_service ||= CustomerService.new(customer_repo: CustomerRepository.new(DB))
  end

  def parse_json_body
    JSON.parse(request.body.read, symbolize_names: true)
  rescue JSON::ParserError
    halt 400, json(error: 'Invalid JSON')
  end

  def build_hourly_buckets(data)
    now = Time.now.utc
    24.times.map do |i|
      hour = (now - ((23 - i) * 3600)).strftime('%Y-%m-%dT%H:00:00Z')
      { hour: hour, visits: data[hour] || 0 }
    end
  end
end

error ArgumentError do |e|
  halt 400, json(error: e.message)
end

error PersistenceError do
  halt 500, json(error: 'Internal server error')
end

get '/' do
  content_type :html
  send_file File.join(settings.public_folder, 'index.html')
end

post '/api/visits' do
  body = parse_json_body
  visit_service.record(customer_id: body[:customer_id], device_id: body[:device_id])
  status 201
  json customer_service.find(body[:customer_id])
end

get '/api/customers' do
  json customer_service.all
end

get '/api/customers/:id' do
  customer = customer_service.find(params[:id])
  halt 404, json(error: 'Customer not found') unless customer
  json customer
end

get '/api/stats/hourly' do
  json build_hourly_buckets(visit_service.hourly_stats)
end
