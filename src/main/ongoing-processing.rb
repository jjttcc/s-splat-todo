#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'configuration'
require 'stodomanager'


manager = STodoManager.new(service_name: 'ongoing-processing')
manager.perform_ongoing_processing
