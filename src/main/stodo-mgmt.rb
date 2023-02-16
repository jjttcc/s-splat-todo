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
  when /obsolete-add/
    require 'templatetargetbuilder'
    require 'templateoptions'
    type = arguments[0]
    handle = arguments[1]
$log.warn "type: #{type}, handle: #{handle}"
    command_and_args = [command, type, arguments[2..-1]].flatten
    if command_and_args.count < 2 then
      two_arg_warning command
    else
      target_builder = TemplateTargetBuilder.new TemplateOptions.new
$log.warn "ARGV: #{ARGV.inspect}"
exit 47
      manager.add_new_target(handle, command_and_args, target_builder)
    end
  when /add/
    require 'templatetargetbuilder'
    require 'templateoptions'
$log.warn "[smgmg] arguments: #{arguments}"
    target_builder = TemplateTargetBuilder.new TemplateOptions.new arguments
$log.warn "ARGV: #{ARGV.inspect}"
    manager.add_new_targets(target_builder.targets)
  else
    # Iterate over item handles:
    arguments.each do |h|
      manager.edit_target(h, command)
    end
  end
end
