#!/usr/bin/env ruby
# Management of s*todo data - Apply <command> to the specified handles.

require 'configuration'
require 'stodomanager'

def two_arg_warning command
  $log.warn "Wrong number of arguments - usage: #{command} <arg1> <arg2>"
end

if ARGV.length > 1 then
  manager = STodoManager.new Configuration.new
  command = ARGV[0]; arguments = ARGV[1..-1]
  case command
  when /ch.*par/, /clone/, /remove_d/, /ch.*han/  # two+-arg commands
    handle = arguments[0]
    command_and_args = [command, arguments[1..-1]].flatten
    if command_and_args.count < 2 then
      two_arg_warning command
    else
      manager.edit_target(handle, command_and_args)
    end
  when /add/
    require 'templatetargetbuilder'
    require 'templateoptions'
    target_builder = TemplateTargetBuilder.new(
      TemplateOptions.new arguments, true)
    manager.add_new_targets(target_builder.targets)
  else
    # Iterate over item handles:
    arguments.each do |h|
      manager.edit_target(h, command)
    end
  end
end
