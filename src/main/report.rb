#!/usr/bin/env ruby
# Display a report of existing s*todo items.

require 'configuration'
require 'stodomanager'


config = Configuration.new
manager = STodoManager.new config
manager.list_targets
manager.report_targets_descendants
