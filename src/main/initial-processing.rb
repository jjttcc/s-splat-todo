#!/usr/bin/env ruby
# Execute initial processing of new s*todo items based on new specs.

require 'memorandum'
require 'configuration'
require 'filebasedspecgatherer'
require 'targetbuilder'
require 'stodomanager'


Configuration.service_name = 'initial-processing'
Configuration.debugging = false
# Gather the new specs.
spec_collector = FileBasedSpecGatherer.new
# Build the s*todo targets.
target_builder = TargetBuilder.new spec_collector
manager = STodoManager.new(target_builder: target_builder)
manager.perform_initial_processing
$log.warn("test init-proc")
