#!/usr/bin/env ruby
# Management of s*todo data - Apply <command> to the specified handles.

require 'configuration'
require 'stodomanager'
require 'stubbedspec'
require 'templatetargetbuilder'

def two_arg_warning command
  $log.warn "Wrong number of arguments - usage: #{command} <arg1> <arg2>"
end

OPT_CHAR = '-'

# command-line options (marked with OPT_CHAR) from 'arguments'
# Assumption: All elements from the first occurrence in 'arguments' of
# OPT_CHAR to the end of the array are options.
def opts_from_args arguments
  result = []
  opt_ind = -1
  (0 .. arguments.count - 1).each do |i|
    if arguments[i] =~ /^#{OPT_CHAR}/ then
      opt_ind = i
      break
    end
  end
  if opt_ind >= 0 then
    result = arguments[opt_ind .. -1]
  end
  result
end

# handles from 'arguments' - everything up to, but not including, the
# first occurrence of OPT_CHAR
def handles_from_args arguments
  result = []
  arguments.each do |a|
    if a =~ /^#{OPT_CHAR}/ then
      break
    else
      result << a
    end
  end
  result
end

if ARGV.length > 1 then
  manager = STodoManager.new(service_name: 'management', debugging: true)
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
    manager.update_targets(options)
  else
    require 'templateoptions'
    opts = opts_from_args(arguments)
    handles = handles_from_args(arguments)
    handles.each do |h|
      if ! opts.empty? then
        manager.edit_target(h, command, opts)
      else
        manager.edit_target(h, command)
      end
    end
    manager.close_edit
  end
$log.warn("test mgmt[1]")
end
