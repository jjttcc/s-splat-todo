#!/usr/bin/env ruby
# Execute initial processing of new "s*todo" items based on new specs.

require_relative 'compositetask.rb'
require_relative 'memorandum'
require_relative 'configuration'
require_relative 'filebasedspecgatherer'
require_relative 'targetbuilder'
require_relative 'actiontargetmanager'


config = Configuration.new
# Gather the new specs.
spec_collector = FileBasedSpecGatherer.new config
# Build the "s*todo" targets.
target_builder = TargetBuilder.new spec_collector.specs
manager = ActionTargetManager.new target_builder.targets, config
manager.perform_initial_processing
manager.perform_notifications
#!!!!To-do: singleton hash-table: key: handle, value: ActionTarget
#!!!!Use it, among other things, to prevent duplicate handles.
