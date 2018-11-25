if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    minimum_coverage 100
    add_filter "/test/"
  end
end

require 'minitest/autorun'
require_relative '../lib/tubby'

