# frozen_string_literal: true
require "cgi"

module Tubby
  def self.new(&blk)
    Template.new(&blk)
  end

  class Template
    def initialize(&blk)
      @blk = blk
    end

    def to_s
      target = String.new
      renderer = Renderer.new(target)
      render_with(renderer)
      target
    end

    def to_html
      to_s
    end

    def render_with(renderer)
      @blk.call(renderer)
    end
  end

  class Renderer
    def initialize(target)
      @target = target
    end

    def <<(obj)
      obj = obj.to_tubby if obj.respond_to?(:to_tubby)
      if obj.is_a?(Tubby::Template)
        obj.render_with(self)
      elsif obj.respond_to?(:to_html)
        @target << obj.to_html
      elsif obj.respond_to?(:html_safe?) && obj.html_safe?
        @target << obj
      else
        @target << CGI.escape_html(obj.to_s)
      end
      self
    end

    def raw!(text)
      @target << text.to_s
    end

    def doctype!
      @target << "<!DOCTYPE html>"
    end

    def __attrs!(attrs)
      if attrs.key?(:data) && attrs[:data].is_a?(Hash)
        # Flatten present `data: {k1: v1, k2: v2}` attribute, inserting `data-k1: v1, data-k2: v2`
        # into exact place where the attribute was
        attrs = attrs.map do |key, value|
          if key == :data && value.is_a?(Hash)
            value.map { |k, v| [:"data-#{k}", v] }
          else
            [[key, value]]
          end
        end.flatten(1).to_h
      end

      attrs.each do |key, value|
        if value.is_a?(Array)
          value = value.compact.join(" ")
        end

        if value
          key = key.to_s.tr("_", "-")

          if value == true
            @target << " #{key}"
          else
            value = CGI.escape_html(value.to_s)
            @target << " #{key}=\"#{value}\""
          end
        end
      end
    end

    def tag!(name, content = nil, **attrs)
      @target << "<" << name
      __attrs!(attrs)
      @target << ">"
      self << content if content
      yield if block_given?
      @target << "</" << name << ">"
    end

    def self_closing_tag!(name, **attrs)
      @target << "<" << name
      __attrs!(attrs)
      @target << ">"
    end

    TAGS = %w[
      a abbr acronym address applet article aside audio b basefont bdi bdo big
      blockquote body button canvas caption center cite code colgroup datalist
      dd del details dfn dir div dl dt em fieldset figcaption figure font footer
      form frame frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins
      kbd label legend li map mark math menu meter nav
      object ol optgroup option output p pre progress q rp rt ruby s samp
      section select small span strike strong style sub summary sup svg table
      tbody td textarea tfoot th thead time title tr tt u ul var video xmp
    ]

    SELF_CLOSING_TAGS = %w[
      base link meta hr br wbr img embed param source track area col input
      keygen command
    ]

    TAGS.each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}(content = nil, **attrs, &blk)
          tag!(#{name.inspect}, content, **attrs, &blk)
        end
      RUBY
    end

    SELF_CLOSING_TAGS.each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}(**attrs)
          self_closing_tag!(#{name.inspect}, **attrs)
        end
      RUBY
    end

    def script(content = nil, **attrs)
      @target << "<script"
      __attrs!(attrs)
      @target << ">"
      if content
        if content =~ /<(!--|script|\/script)/
          raise "script tags can not contain #$&"
        end
        @target << content
      end
      @target << "</script>"
    end
  end
end

