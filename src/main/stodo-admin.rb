#!/usr/bin/env ruby
# s*todo administration facilities

require 'configuration'
require 'stodoadministrator'

if ! ARGV.empty? then
  administrator = STodoAdministrator.new
  administrator.execute(ARGV)
end
