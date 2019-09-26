# Tubby: Tags in Ruby

[![](https://img.shields.io/gem/v/tubby.svg)](https://rubygems.org/gems/tubby) [![](https://img.shields.io/travis/com/judofyr/tubby.svg)](https://travis-ci.com/judofyr/tubby) 

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

Table of contents:

- [Basic usage](#basic-usage)
- [Advanced usage](#advanced-usage)
- [Versioning](#versioning)
- [License](#license)

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

## Advanced usage

The variable `t` in all of the examples above is an instance of
`Tubby::Renderer`. Calling `Tubby::Template#to_s` is a shortcut for the
following:

```ruby
tmpl = Tubby.new { |t|
  # content inside here
}

# This:
puts tmpl.to_s

# ... is the same as:
target = String.new
t = Tubby::Renderer.new(target)
t << tmpl
puts target
```

Let's look at two ways we can customize Tubby.

### Custom target

The target object doesn't have to be a String, it must only be an object which
responds to `<<`. Using a custom target might be useful if you want stream the
HTML directly into a socket/file. For instance, this will print the HTML out to
the standard output:

```ruby
tmpl = Tubby.new { |t|
  t.h1("Hello terminal!")
}

t = Tubby::Renderer.new($stdout)
t << tmpl
```

### Custom renderer

You are also free to subclass the Renderer to provide additional helpers/data:

```ruby
tmpl = Tubby.new { |t|
  t.post_form(action: t.login_path) {
    t.input(name: "username")
    t.input(type: "password", name: "password")
  }
}

class Renderer < Tubby::Renderer
  include URLHelpers

  attr_accessor :csrf_token

  # Renders a <form>-tag with the csrf_token
  def post_form(**opts)
    form(method: "post", **opts) {
      input(type: "hidden", name: "csrf_token", value: csrf_token)
      yield
    }
  end
end

target = String.new
t = Renderer.new(target)
t.csrf_token = "hello"
t << tmpl
puts target
```

You should use this feature with care as it makes your components coupled to the
data you provide. For instance, it might be tempting to have access to the Rack
environment as `t.rack_env`, but this means you can no longer render any HTML
outside of a Rack context (e.g: generating email). For CSRF token it makes
sense: it's a value which is global for the whole page, you might need it deeply
nested inside a component, and it's a hassle to pass it along.

In general however you should prefer separate classes over custom renderer methods:

```ruby
# Do this:

class OkCancel
  def initialize(cancel_link:)
    @cancel_link = cancel_link
  end

  def to_tubby
    Tubby.new { |t|
      t.div(class: "btn-group") {
        t.button("Save", class: "btn", type: "submit")
        t.a("Cancel", class: "btn", href: @cancel_link)
      }
    }
  end
end

tmpl = Tubby.new { |t|
  t << OkCancel.new(cancel_link: "/users")
}

# Don't do this:

class Renderer < Tubby::Renderer
  def ok_cancel(cancel_link:)
    Tubby.new { |t|
      t.div(class: "btn-group") {
        t.button("Save", class: "btn", type: "submit")
        t.a("Cancel", class: "btn", href: cancel_link)
      }
    }
  end
end

tmpl = Tubby.new { |t|
  t.ok_cancel(cancel_link: "/users")
}
```

## Versioning

Tubby uses version numbers on the form MAJOR.MINOR, and releases are backwards
compatible with earlier releases with the same MAJOR version.

## License

Tubby is is available under the Blue Oak Model License (see LICENSE.md).
This is a permissive license similar to BSD/MIT.
