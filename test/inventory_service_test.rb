require "minitest/autorun"
require "inventory_service"

class TestInventoryService < Minitest::Test
  SKU = 'abc123'

  def service
    @service ||= InventoryService.new(couch: couch)
  end

  def couch
    @couch ||= begin
      server = CouchRest.new
      db = server.database!('inventory_service_test')
      doc = begin
        db.get(SKU)
      rescue RestClient::ResourceNotFound
        nil
      end
      db.delete_doc(doc) if doc
      db
    end
  end

  def test_get_with_no_match
    res = service.get('not_found_sku')
    assert res == nil
  end

  def test_get_with_match
    doc = {
      "_id" => SKU,
      "inventory" => {
        "size_1" => 10
      }
    }
    couch.save_doc(doc)

    doc = service.get(SKU)
    assert doc['inventory'] == {"size_1" => 10}
  end
end
