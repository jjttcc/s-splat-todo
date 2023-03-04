#!/usr/bin/env ruby
# Output a to-do item template.

require 'configuration'
require 'stodomanager'
require 'templatetargetbuilder'
require 'templateoptions'

include SpecTools

target_builder = TemplateTargetBuilder.new TemplateOptions.new
target_builder.set_processing_mode(TemplateTargetBuilder::CREATE_MODE)
manager = STodoManager.new Configuration.new
manager.target_builder = target_builder
manager.output_template
