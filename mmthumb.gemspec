# encoding: utf-8
#

require File.expand_path('../lib/mmthumb/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'mmthumb'
  s.version       = MMThumb::VERSION
  s.date          = Time.now

  s.summary       = %q{Convenient image converter for common workflows}
  s.description   = %q{Define pre-, post- and a number of output operations and let MMThumb do the work. Will fit well with offline batch-processing just as well as as a component of a continuous online service. Single dependency.}
  s.license       = 'BSD'
  s.authors       = ['Piotr S. Staszewski']
  s.email         = 'p.staszewski@gmail.com'
  s.homepage      = 'https://github.com/drbig/mmthumb'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = s.files.grep(%r{^spec/})
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'mini_magick', '~> 3.7'

  s.add_development_dependency 'rspec', '~> 2.4'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
  s.add_development_dependency 'yard', '~> 0.8'
end
