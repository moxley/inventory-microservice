require "minitest/autorun"
require "inventory_service"

class TestInventoryService < Minitest::Test
  SKU = 'abc123'
  SIMPLE_DOC = {
    "_id" => SKU,
    "inventory" => {
      "size_1" => 10
    }
  }

  attr_reader :couch

  def service
    @service ||= InventoryService.new(couch: couch)
  end

  def setup
    @couch ||= begin
      server = CouchRest.new
      server.database!('inventory_service_test')
    end
  end

  def teardown
    couch.delete!
  end

  def test_get_with_no_match
    res = service.get('not_found_sku')
    assert res == nil
  end

  def test_get_with_match
    couch.save_doc(SIMPLE_DOC)

    doc = service.get(SKU)
    assert doc['inventory'] == SIMPLE_DOC['inventory']
  end

  def test_set_with_match
    couch.save_doc(SIMPLE_DOC)

    res = service.set(SKU, {"size_1" => 101})
    doc = service.get(SKU)
    assert doc['inventory'] == {"size_1" => 101}, "inventory didn't match. Was: #{doc['inventory'].inspect}"
  end

  def test_set_without_match
    res = service.set(SKU, {"size_1" => 101})
    doc = service.get(SKU)
    assert doc['inventory'] == {"size_1" => 101}, "inventory didn't match. Was: #{doc['inventory'].inspect}"
  end
end
