#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require_relative 'compositetask.rb'
require_relative 'memorandum'
require_relative 'configuration'
require_relative 'filebasedspecgatherer'
require_relative 'targetbuilder'
require_relative 'stodomanager'


config = Configuration.new
manager = STodoManager.new config
manager.perform_ongoing_processing
