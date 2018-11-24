require_relative 'helper'

class TestTubby < Minitest::Test
  def test_basic
    tmpl = Tubby.new { |t|
      t.h1("Hello world!")
    }

    assert_equal "<h1>Hello world!</h1>", tmpl.to_s
    assert_equal tmpl.to_html, tmpl.to_s
  end

  def test_escape
    tmpl = Tubby.new { |t|
      t.h1("A & B")
      t << "C & D"
    }

    assert_equal "<h1>A &amp; B</h1>C &amp; D", tmpl.to_s
  end

  def test_append
    a = Tubby.new { |t|
      t.h1("Child")
    }

    b = Object.new
    def b.to_s
      "b&c"
    end

    c = Object.new
    def c.to_html
      "c&b"
    end

    tmpl = Tubby.new { |t|
      t << nil
      t << "a"
      t << 1
      t << a
      t << b
      t << c
    }

    assert_equal "a1<h1>Child</h1>b&amp;cc&b", tmpl.to_s
  end

  def test_raw
    tmpl = Tubby.new { |t|
      t.raw! "<b>Yes!</b>"
    }

    assert_equal "<b>Yes!</b>", tmpl.to_s
  end

  def test_doctype
    tmpl = Tubby.new { |t|
      t.doctype!
    }

    assert_equal "<!DOCTYPE html>", tmpl.to_s
  end
end

