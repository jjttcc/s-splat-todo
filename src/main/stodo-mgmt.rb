#!/usr/bin/env ruby
# Management of s*todo data - Apply <command> to the specified handles.

require 'configuration'
require 'stodomanager'
require 'stubbedspec'
require 'templatetargetbuilder'

def two_arg_warning command
  $log.warn "Wrong number of arguments - usage: #{command} <arg1> <arg2>"
end

if ARGV.length > 1 then
  manager = STodoManager.new
  command = ARGV[0]; arguments = ARGV[1..-1]
  case command
  when /^ch.*par/, /^clone/, /^remove_d/, /^ch.*han/  # two+-arg commands
    handle = arguments[0]
    command_and_args = [command, arguments[1..-1]].flatten
    if command_and_args.count < 2 then
      two_arg_warning command
    else
      manager.edit_target(handle, command_and_args)
      manager.close_edit
    end
  when /^add/
    require 'templatetargetbuilder'
    require 'templateoptions'
    options = TemplateOptions.new(arguments, true)
    target_builder = TemplateTargetBuilder.new(options,
                                               manager.existing_targets)
    target_builder.set_processing_mode TemplateTargetBuilder::CREATE_MODE
    manager.target_builder = target_builder
    manager.add_new_targets
  when /^change*/
    require 'templateoptions'
    handle = arguments[0]
    $log.debug "arguments: #{arguments}, handle: #{handle}"
    # unshift: Adapt to the expected arg/options format (i.e.: '-h <handle'):
    arguments.unshift '-h'
    arguments.unshift SpecTools::EDIT   # (the 'type' argument)
    $log.debug "arguments: #{arguments}"
    options = TemplateOptions.new(arguments, true)
    spec = StubbedSpec.new(options, false)  # false => don't use defaults
    target_editor = TemplateTargetBuilder.new(options,
                                              manager.existing_targets, spec)
    manager.target_builder = target_editor
    manager.update_targets
  else
    opts = arguments.select do |a| a[0] == '-' end
    handles = arguments.select do |a| a[0] != '-' end
    handles.each do |h|
      if ! opts.empty? then
        manager.edit_target(h, command, opts)
      else
        manager.edit_target(h, command)
      end
    end
    manager.close_edit
  end
end
