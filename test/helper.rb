require 'simplecov'
SimpleCov.start do
  minimum_coverage 100
  add_filter "/test/"
end

require 'minitest/autorun'
require_relative '../lib/tubby'

