#!/usr/bin/env ruby
# Execute ongoing processing of s*todo items.

require 'stodo_cli_repl'

server = STodoCliREPL.new
server.execute
