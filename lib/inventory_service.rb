require 'couchrest'

# TODO Check sku to valid format
class InventoryService
  class NotFound < StandardError
  end

  def initialize(opts = {})
    @couch = opts[:couch]
  end

  def get(sku)
    begin
      couch.get(sku)
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  def set(sku, inventory)
    doc = get(sku)
    if doc
      doc["inventory"] = inventory
    else
      doc = {
        "_id" => sku,
        "inventory" => inventory
      }
    end
    couch.save_doc(doc)
  end

  def adjust(sku, size, amount)
    doc = get(sku)
    raise NotFound, "Not found for sku: #{sku}" unless doc
    old_amount = doc["inventory"][size]
    raise NotFound, "Not found for size: #{sku}" unless old_amount
    new_amount = old_amount - amount
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
end
