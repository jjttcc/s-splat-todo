#!/usr/bin/env ruby
# Execute initial processing of new s*todo items based on new specs.

require 'compositetask.rb'
require 'memorandum'
require 'configuration'
require 'filebasedspecgatherer'
require 'targetbuilder'
require 'stodomanager'


config = Configuration.new
# Gather the new specs.
spec_collector = FileBasedSpecGatherer.new config
# Build the s*todo targets.
target_builder = TargetBuilder.new spec_collector
manager = STodoManager.new config, target_builder
if manager.new_targets != nil then
  manager.perform_initial_processing
end
