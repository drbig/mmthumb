# encoding: utf-8
#

require 'rspec'

RSpec.configure do |c|
  c.expect_with :rspec do |cc|
    cc.syntax = :expect
  end
end
