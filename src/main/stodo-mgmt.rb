#!/usr/bin/env ruby
# Management of s*todo data - Apply <command> to the specified handles.

require 'configuration'
require 'stodomanager'

if ARGV.length > 1 then
  manager = STodoManager.new Configuration.new
  command = ARGV[0]; handles = ARGV[1..-1]
  handles.each do |h|
    manager.edit_target(h, command)
  end
end
