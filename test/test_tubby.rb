require_relative 'helper'

class TestTubby < Minitest::Test
  def test_basic
    tmpl = Tubby.new { |t|
      t.h1("Hello world!")
    }

    assert_equal "<h1>Hello world!</h1>", tmpl.to_s
  end

  def test_escape
    tmpl = Tubby.new { |t|
      t.h1("A & B")
      t << "C & D"
    }

    assert_equal "<h1>A &amp; B</h1>C &amp; D", tmpl.to_s
  end
end

