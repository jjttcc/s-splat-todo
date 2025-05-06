#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'configuration'
require 'stodomanager'


Configuration.service_name = 'ongoing-processing'
Configuration.debugging = false
config = Configuration.instance
manager = config.new_stodo_manager(service_name: 'ongoing-processing',
                                   debugging: true)
manager.perform_ongoing_processing
