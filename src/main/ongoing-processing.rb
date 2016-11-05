#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'configuration'
require 'stodomanager'


config = Configuration.new
manager = STodoManager.new config
manager.perform_ongoing_processing
