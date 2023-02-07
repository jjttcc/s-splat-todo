#!/usr/bin/env ruby
# Management of s*todo data - Apply <command> to the specified handles.

require 'configuration'
require 'stodomanager'

if ARGV.length > 1 then
  manager = STodoManager.new Configuration.new
  command = ARGV[0]; arguments = ARGV[1..-1]
  case command
  when /ch.*par/  # change parent
    handle = arguments[0]
    command_and_args = [command, arguments[1..-1]].flatten
    manager.edit_target(handle, command_and_args)
  else
    # Iterate over item handles:
    arguments.each do |h|
      manager.edit_target(h, command)
    end
  end
end
