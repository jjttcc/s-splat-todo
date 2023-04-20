#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'configuration'
require 'stodomanager'


manager = STodoManager.new
$log.warn "manager.perform_ongoing_processing (#{})"
manager.perform_ongoing_processing
