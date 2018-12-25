# -*- encoding: utf-8 -*-
require 'date'

Gem::Specification.new do |s|
  s.name          = 'tubby'
  s.version       = ENV['TUBBY_VERSION'] || "1.master"
  s.date          = Date.today.to_s

  s.authors       = ['Magnus Holm']
  s.email         = ['judofyr@gmail.com']
  s.summary       = 'HTML templates as Ruby'
  s.homepage      = 'https://github.com/judofyr/tubby'

  s.require_paths = %w(lib)
  s.files         = Dir["lib/**/*.rb"] + Dir["*.md"]
  s.license       = '0BSD'
end

