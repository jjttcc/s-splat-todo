#!/usr/bin/env ruby
# Output a to-do item template.

require 'configuration'
require 'stodomanager'
require 'templatetargetbuilder'
require 'templateoptions'

include SpecTools

manager = STodoManager.new(service_name: 'template')
target_builder = TemplateTargetBuilder.new TemplateOptions.new
target_builder.set_processing_mode(TemplateTargetBuilder::CREATE_MODE)
manager.target_builder = target_builder
$log.warn("test template[1]")
manager.output_template
$log.warn("test template[2]")
