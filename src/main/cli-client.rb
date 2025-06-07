#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'stodo_cli_client'

server = STodoCliClient.new
server.execute
