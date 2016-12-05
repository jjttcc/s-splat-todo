#!/usr/bin/env ruby
# s*todo administration facilities

require 'configuration'
require 'stodoadministrator'

if ! ARGV.empty? then
  administrator = STodoAdministrator.new Configuration.new
  administrator.execute(ARGV)
end
