#!/usr/bin/env ruby
# Display a report of existing s*todo items.

require_relative 'configuration'
require_relative 'stodomanager'


config = Configuration.new
manager = STodoManager.new config
manager.report_targets_descendants(manager.existing_targets)
