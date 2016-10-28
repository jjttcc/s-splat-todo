#!/usr/bin/env ruby
# Output a to-do item template.

require_relative 'configuration'
require_relative 'stodomanager'
require_relative 'templatetargetbuilder'

DEFAULT_TYPE='appointment'
type = ARGV.length > 0 ? ARGV[0] : DEFAULT_TYPE
target_builder = TemplateTargetBuilder.new type
manager = STodoManager.new
manager.output_template target_builder
