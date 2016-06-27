require "minitest/autorun"
require "inventory_service"

class TestInventoryService < Minitest::Test
  class MyError < RuntimeError
  end

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
    # Prevent test output pollution
    Stoplight::Light.default_error_notifier = -> _ {}
    Stoplight::Light.default_notifiers = []
    Stoplight::Light.default_data_store = Stoplight::DataStore::Memory.new

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

  def test_adjust_without_sku_match
    begin
      service.adjust(SKU, "size_1", 1)
      fail "Should have raised error"
    rescue InventoryService::NotFound
      # Expected
    end
  end

  def test_adjust_without_size_match
    service.set(SKU, {})
    begin
      service.adjust(SKU, "unknown_size", 1)
      fail "Should have raised error"
    rescue InventoryService::NotFound
      # Expected
    end
  end

  def test_adjust_with_match
    service.set(SKU, {"size_1" => 100})
    service.adjust(SKU, "size_1", 1)
    doc = service.get(SKU)
    assert doc["inventory"] == {"size_1" => 99}
  end

  def test_set_with_failed_couchdb
    def couch.get(sku)
      raise Errno::ECONNRESET, "Dummy error"
    end

    call_service_with_error_green_light
    call_service_with_error_green_light
    call_service_with_error_green_light

    # Now at red light
    call_service_with_error_red_light
    call_service_with_error_red_light
    call_service_with_error_red_light
  end

  def call_service_with_error_green_light
    begin
      service.get(SKU)
      fail "Should have raised Errno::ECONNRESET"
    rescue Errno::ECONNRESET
      # Expected
    end
  end

  def call_service_with_error_red_light
    begin
      service.get(SKU)
      fail "Should have raised Stoplight::Error::RedLight"
    rescue Stoplight::Error::RedLight
      # Expected
    end
  end

  def closed_circuit_error(&block)
    begin
      with_circuit_breaker do
        yield
        fail "Should have raised MyError"
      end
    rescue Errno::ECONNRESET
      # Expected
    end
  end
end
