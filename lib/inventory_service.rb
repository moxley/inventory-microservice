require "couchrest"
require "stoplight"

# TODO Check sku to valid format
class InventoryService
  class NotFound < StandardError
  end

  def initialize(opts = {})
    @couch = opts[:couch]
  end

  def get(sku)
    begin
      with_circuit_breaker do
        couch.get(sku)
      end
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  def set(sku, inventory)
    inventory = inventory.
      keys.
      reduce({}) do |new_inventory, key|
        new_inventory.merge(key => inventory[key].to_i)
      end

    doc = get(sku)
    if doc
      doc["inventory"] = inventory
    else
      doc = {
        "_id" => sku,
        "inventory" => inventory
      }
    end
    with_circuit_breaker do
      couch.save_doc(doc)
    end
  end

  def adjust(sku, size, amount)
    doc = get(sku)
    raise NotFound, "Not found for sku: #{sku}" unless doc
    old_amount = doc["inventory"][size]
    raise NotFound, "Not found for size: #{sku}" unless old_amount
    new_amount = old_amount.to_i + amount.to_i
    doc["inventory"][size] = new_amount
    set(sku, doc["inventory"])
  end

  private

  def couch
    @couch ||= begin
      server = CouchRest.new
      server.database!('inventory_service')
    end
  end

  def with_circuit_breaker(&block)
    Stoplight('couchdb') do
      yield
    end.with_cool_off_time(10).
      run
  end
end
