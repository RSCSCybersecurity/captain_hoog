ENV['PREGIT_ENV'] = 'test'

require 'captain_hoog/test/sandbox'
require 'captain_hoog/test/rspec' if defined?(RSpec)
