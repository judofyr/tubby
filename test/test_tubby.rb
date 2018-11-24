require_relative 'helper'

class TestTubby < Minitest::Test
  def test_basic
    tmpl = Tubby.new { |t|
      t.h1("Hello world!")
    }

    assert_equal "<h1>Hello world!</h1>", tmpl.to_s
  end
end

