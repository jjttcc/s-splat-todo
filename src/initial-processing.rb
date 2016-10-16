#!/usr/bin/env ruby
# Execute initial processing of new "s*todo" items based on new specs.

require_relative 'compositetask.rb'
require_relative 'memorandum'
require_relative 'configuration'
require_relative 'filebasedspecgatherer'
require_relative 'targetbuilder'
require_relative 'stodomanager'


ongoing_actions_are_to_be_performed_counter_to_commens_sense = false
config = Configuration.new
# Gather the new specs.
spec_collector = FileBasedSpecGatherer.new config
# Build the "s*todo" targets.
target_builder = TargetBuilder.new spec_collector
manager = STodoManager.new target_builder, config
manager.perform_initial_processing
if ongoing_actions_are_to_be_performed_counter_to_commens_sense then
  manager.perform_notifications
end
#!!!!To-do: singleton hash-table: key: handle, value: STodoTarget
#!!!!Use it, among other things, to prevent duplicate handles.
