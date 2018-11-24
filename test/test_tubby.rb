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

  def test_self_closing
    tmpl = Tubby.new { |t|
      t.br
    }

    assert_equal "<br>", tmpl.to_s

    assert_raises(ArgumentError) do
      tmpl = Tubby.new { |t|
        t.br("hello")
      }.to_s
    end
  end

  def test_content
    tmpl = Tubby.new { |t|
      t.div("a")
      t.div {
        t << "a"
      }
      t.div("a") {
        t << "b"
      }
    }

    assert_equal "<div>a</div><div>a</div><div>ab</div>", tmpl.to_s
  end

  def test_attrs
    tmpl = Tubby.new { |t|
      t.h1(a: false, b: nil, c: "", d: 123, e: [], f: [nil, 1, false, 2], g: true)
    }

    assert_equal '<h1 c="" d="123" e="" f="1 2" g></h1>', tmpl.to_s
  end

  class HTMLBuffer < String
    def html_safe?
      @html_safe == true
    end

    def html_safe!
      @html_safe = true
      self
    end
  end

  def test_html_safe
    tmpl = Tubby.new { |t|
      text = HTMLBuffer.new("a&b").html_safe!
      t.h1(text)
    }

    assert_equal "<h1>a&b</h1>", tmpl.to_s
  end

  def test_custom_target
    tmpl = Tubby.new { |t|
      t.h1("Hello")
    }

    result = tmpl.render_into([])
    assert_instance_of Array, result
    assert_equal "<h1>Hello</h1>", result.join
  end
end

