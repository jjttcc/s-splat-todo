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
config = Configuration.instance
manager = config.new_stodo_manager(service_name: 'initial-processing',
                                   debugging: true)
manager.target_builder = target_builder
manager.perform_initial_processing
