#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'configuration'
require 'stodomanager'


# (Configuration.initialize makes its "self" available via
#  class method Configuration.config)
Configuration.new
manager = STodoManager.new
manager.perform_ongoing_processing
