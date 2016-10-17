#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require_relative 'compositetask.rb'
require_relative 'memorandum'
require_relative 'configuration'
require_relative 'filebasedspecgatherer'
require_relative 'targetbuilder'
require_relative 'stodomanager'


config = Configuration.new
# Gather the new specs.
spec_collector = FileBasedSpecGatherer.new(config, false)
# Build the "s*todo" targets.
target_builder = TargetBuilder.new spec_collector
manager = STodoManager.new target_builder, config
manager.perform_ongoing_processing
