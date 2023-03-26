#!/usr/bin/env ruby
# Execute initial processing of new s*todo items based on new specs.

require 'memorandum'
require 'configuration'
require 'filebasedspecgatherer'
require 'targetbuilder'
require 'stodomanager'


Configuration.new
# (Configuration.initialize makes its "self" available via
#  class method Configuration.config)
# Gather the new specs.
spec_collector = FileBasedSpecGatherer.new
# Build the s*todo targets.
target_builder = TargetBuilder.new spec_collector
manager = STodoManager.new target_builder
manager.perform_initial_processing
