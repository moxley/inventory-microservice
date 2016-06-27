require 'couchrest'

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
