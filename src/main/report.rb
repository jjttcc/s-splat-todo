#!/usr/bin/env ruby
# Display a report of existing s*todo items.

require 'configuration'
require 'stodomanager'


config = Configuration.new
manager = STodoManager.new config
manager.report_targets_descendants(manager.existing_targets)
