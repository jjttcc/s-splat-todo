#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'configuration'
require 'stodomanager'


manager = STodoManager.new
manager.perform_ongoing_processing
