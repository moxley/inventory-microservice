require "minitest/autorun"
require "inventory_service"

class TestInventoryService < Minitest::Test
  def test_get_with_no_match
    service = InventoryService.new
    res = service.get('not_found_sku')
    assert res == nil
  end
end
