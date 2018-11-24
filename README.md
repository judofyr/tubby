# Tubby: Tags in Ruby

Tubby is a lightweight library for writing HTML components in plain Ruby.

```ruby
tmpl = Tubby.new { |t|
  t.doctype!

  t.h1("Hello #{current_user}!")

  t << Avatar.new(current_user)

  t.ul {
    t.li("Tinky Winky")
    t.li("Dipsy", class: "active")
    t.li("Laa-Laa")
    t.li("Po")
  }
}

class Avatar
  def initialize(user)
    @user = user
  end

  def url
    # Calculate URL
  end

  def to_tubby
    Tubby.new { |t|
      t.div(class: "avatar") {
        t.img(src: url)
      }
    }
  end
end

puts tmpl.to_s
```

## Basic usage

### Creating templates

`Tubby.new` accepts a block and returns a `Tubby::Template`:

```ruby
tmpl = Tubby.new { |t|
  # content inside here
}
```

The block will be executed once you call `#to_s` (or its alias `#to_html`):

```ruby
puts tmpl.to_s
```

### Writing HTML tags

The following forms are available for writing HTML inside a template:

```ruby
# Empty tag
t.h1
# => <h1></h1>

# Tag with content
t.h1("Welcome!")
# => <h1>Welcome!</h1>

# Tag with attributes
t.h1(class: "big")
# => <h1 class="big"></h1>

# Tag with attributes and content
t.h1("Welcome!", class: "big")
# => <h1 class="big">Welcome!</h1>

# Tag with block content
t.h1 {
  t.span("Hello")
}
# => <h1><span>Hello</span></h1>

# Tag with block content and attributes
t.h1(class: "big") {
  t.span("Hello")
}
# => <h1 class="big"><span>Hello</span></h1>

# Tag with block content, attributes and content
t.h1("Hello ", class: "big") {
  t.span("world!")
}
# => <h1 class="big">Hello <span>world!</span></h1>
```

It's recommended to use `{ }`for nesting of tags and `do/end` for nesting of
control flow. At first it looks weird, but otherwise it becomes hard to
visualize the control flow:

```ruby
t.ul {
  users.each do |user|
    t.li {
      t.a(user.name, href: user_path(user))
    }
  end
}
```

### Writing attributes

Tubby supports various ways of writing attributes:

```ruby
# Plain attribute
t.input(value: "hello")
# => <input value="hello">

# nil/false values ignores the attribute
t.input(value: nil)
# => <input>

# A true value doesn't generate a value
t.input(checked: true)
# => <input checked>

# An array will be space-joined
t.input(class: ["form-control", "error"])
# => <input class="form-control error">

# ... but nil values are ignored
t.input(class: ["form-control", ("error" if error)])
# => <input class="form-control">
# => <input class="form-control error">
```

### Writing plain text

Inside a template you can use `<<` to append text:

```ruby
t.h1 {
  t << "Hello "
  t.strong("world")
  t << "!"
}
# => <h1>Hello <strong>world</strong>!</h1>
```

By default, `#to_s` will be called and the value will be escaped:

```ruby
t.h1 {
  t << "Hello & world"
}
# => <h1>Hello &amp; world</h1>
```

There are three ways to avoid escaping:

```ruby
class Other
  def to_html
    "<custom>"
  end
end

# (1) Appending an object which implements #to_html. Tubby will call the method
#     and append the result without escaping it
t << Other.new

# (2) If you're using Rails, html_safe? is respected
t << "<custom>".html_safe!

# (3) There's also a separate helper
t.raw!("<custom>")
```

In addition, there's a helper for writing a HTML5 doctype:

```ruby
t.doctype!
# => <!DOCTYPE html>
```

### Appending other templates

You can also append another template:

```ruby
content = Tubby.new { |t|
  t.h1("Users")
}

main = Tubby.new { |t|
  t.doctype!
  t.head {
    t.title("My App")
  }

  t.body {
    t << content
  }
}
```

This is the main building block for creating composable templates.

### Implementing `#to_tubby`

Before appending, Tubby will call the `#to_tubby` method if it exists:

```ruby
class Avatar
  def initialize(user)
    @user = user
  end

  def url
    # Calculate URL
  end

  def to_tubby
    Tubby.new { |t|
      t.div(class: "avatar") {
        t.img(src: url)
      }
    }
  end
end

tmpl = Tubby.new { |t|
  t << Avatar.new(user)
}
```

`#to_tubby` can return any value that `<<` accepts (i.e. strings that will be
escaped, objects that respond to `#to_html` and so on), but most of the time you
want to create a new template object.

## License

Tubby is is available under the 0BSD license:

> Copyright (C) 2018 Magnus Holm <judofyr@gmail.com>
>
> Permission to use, copy, modify, and/or distribute this software for any
> purpose with or without fee is hereby granted.
>
> THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
> REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
> AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
> INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
> LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
> OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
> PERFORMANCE OF THIS SOFTWARE.
