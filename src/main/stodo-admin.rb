#!/usr/bin/env ruby
# s*todo administration facilities

require 'configuration'
require 'stodoadministrator'

if ! ARGV.empty? then
  administrator = STodoAdministrator.new
$log.warn("test admin[1]")
  administrator.execute(ARGV)
$log.warn("test admin[2]")
end
