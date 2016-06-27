require 'sinatra'
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'inventory_service'

configure do
  set :port, 2000
end

def json_api_response(status, data)
  [
    status,
    {'Content-Type' => 'text/json'},
    JSON.generate({'data' => data})
  ]
end

# curl localhost:2000/abc123
get '/:sku' do |sku|
  service = InventoryService.new
  doc = service.get(sku)
  json_api_response(200, doc)
end

put '/:sku' do |sku|
  service = InventoryService.new
  res = if params['inventory']
    # curl -X PUT -d 'inventory[size_1]=10&inventory[size_2]=20' localhost:2000/abc123
    res = service.set(sku, params['inventory'])
    res["data"]
  elsif params['amount']
    # curl -X PUT -d 'size=size_1&amount=-2' localhost:2000/abc123
    amount = params['amount']
    service.adjust(sku, params['size'], params['amount'])
  end
  json_api_response(201, {"data" => res})
end
