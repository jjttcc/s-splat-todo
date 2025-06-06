#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'stodo_server'

server = STodoServer.new
server.execute
