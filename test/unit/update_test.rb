require 'test_helper'

class UpdateTest < ActiveSupport::TestCase
  test "normal update returns false for pre_process" do
    u = updates(:normal)
    assert_equal u.pre_process!({:body => u.body}), false
  end
  
  test "dm starting with d or p returns hash for pre_process" do
    u = updates(:dm)
    ret = u.pre_process!({:body => u.body})
    assert_equal ret.is_a?(Hash), true
    
    u = updates(:dm2)
    ret = u.pre_process!({:body => u.body})
    assert_equal ret.is_a?(Hash), true
  end
end
