#!/usr/bin/env ruby
# s*todo administration facilities

require 'configuration'
require 'stodoadministrator'

if ! ARGV.empty? then
  # (Configuration.initialize makes its "self" available via
  #  class method Configuration.config)
  Configuration.new
  administrator = STodoAdministrator.new
  administrator.execute(ARGV)
end
