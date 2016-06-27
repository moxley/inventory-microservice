require 'couchrest'

# TODO Check sku to valid format
class InventoryService
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

  def use(sku, size, amount)
  end

  private

  def couch
    @couch ||= begin
      server = CouchRest.new
      server.database!('inventory_service')
    end
  end
end
