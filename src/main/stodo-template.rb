#!/usr/bin/env ruby
# Output a to-do item template.

require 'configuration'
require 'stodomanager'
require 'templatetargetbuilder'
require 'templateoptions'

include SpecTools

Configuration.service_name = 'template'
config = Configuration.instance
manager = config.new_stodo_manager(service_name: 'template', debugging: true)
#target_builder = TemplateTargetBuilder.new TemplateOptions.new
target_builder = TemplateTargetBuilder.new(TemplateOptions.new, nil, config)
target_builder.set_processing_mode(TemplateTargetBuilder::CREATE_MODE)
manager.target_builder = target_builder
manager.output_template
